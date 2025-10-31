///|
pub(all) enum KnfLeftValue {
  Ident(Name)
  ArrayAcc(Name, Name)
  FieldAcc(Name, String)
}

///|
pub fn Context::assign_stmt_to_knf(
  self : Context,
  assign_stmt : @typecheck.AssignStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let (stmts_expr, expr) = self.expr_to_knf(assign_stmt.expr)
  let ty_expr = self.typekind_to_knf(assign_stmt.expr.ty)
  match assign_stmt.op {
    Assign => {
      // let (stmts_expr, expr) = self.expr_to_knf(assign_stmt.expr)
      let stmts_assign = self.assign_stmt_naive_to_knf(
        assign_stmt.left_value,
        expr,
        ty_expr,
      )
      stmts_expr.add(stmts_assign)
    }
    ass_op => {
      let bop = match ass_op {
        PlusAssign => BinaryOp::Add // +=
        MinusAssign => BinaryOp::Sub // -=
        MultAssign => BinaryOp::Mul // *=
        DivAssign => BinaryOp::Div // /=
        ModAssign => BinaryOp::Mod // %=
        _ => raise KnfTransformError("shouldn't be here")
      }
      let (stmts_lexpr, lexpr) = self.left_value_to_expr(assign_stmt.left_value)
      let ty_lexpr = self.type_to_knf(assign_stmt.left_value.ty)
      let name_lexpr = self.expr_to_knf_name_opt(lexpr, ty_lexpr, stmts_lexpr)
      let ty_expr = self.typekind_to_knf(assign_stmt.expr.ty)
      let name_expr = self.expr_to_knf_name_opt(expr, ty_expr, stmts_expr)
      let name_temp = self.add_temp(ty_expr)
      let stmts_before = [
        KnfStmt::Let(
          name_temp,
          ty_expr,
          KnfExpr::Binary(bop, name_lexpr, name_expr),
        ),
      ]
      let stmts_assign = self.assign_stmt_naive_to_knf(
        assign_stmt.left_value,
        KnfExpr::Ident(name_temp),
        ty_expr,
      )
      stmts_lexpr.add(stmts_expr).add(stmts_before).add(stmts_assign)
    }
  }
}

///|
fn Context::assign_stmt_naive_to_knf(
  self : Context,
  left_value : @typecheck.LeftValue,
  expr : KnfExpr,
  ty_expr : Type,
) -> Array[KnfStmt] raise KnfTransformError {
  let (stmts_lval, lval) = self.left_value_to_knf(left_value)
  let stmts_assign = match lval {
    ArrayAcc(arr, idx) => [KnfStmt::ArrayPut(arr, idx, expr)]
    Ident(name) => [KnfStmt::Assign(name, expr)]
    FieldAcc(sname, fname) => {
      let stmts_expr = []
      let name_expr = self.expr_to_knf_name_opt(expr, ty_expr, stmts_expr)
      stmts_expr.add([KnfStmt::StructFieldSet(sname, fname, name_expr)])
    }
  }
  stmts_lval.add(stmts_assign)
}

///|
fn Context::left_value_to_knf(
  self : Self,
  left_value : @typecheck.LeftValue,
) -> (Array[KnfStmt], KnfLeftValue) raise KnfTransformError {
  match left_value.kind {
    ArrayAccess(lval, idx) => {
      let (stmts_lval_inner, expr_lval_inner) = self.left_value_to_expr(lval)
      let (stmts_expr, expr) = self.expr_to_knf(idx)
      let ty_lval_inner = self.type_to_knf(lval.ty)
      let ty_expr = self.typekind_to_knf(idx.ty)
      let name_lval_inner = self.expr_to_knf_name_opt(
        expr_lval_inner, ty_lval_inner, stmts_lval_inner,
      )
      let name_expr = self.expr_to_knf_name_opt(expr, ty_expr, stmts_expr)
      let stmts = stmts_lval_inner.add(stmts_expr)
      (stmts, KnfLeftValue::ArrayAcc(name_lval_inner, name_expr))
    }
    Ident(id) => {
      let (name, _) = self
        .lookup_name(id)
        .or_error(KnfTransformError("unable to find \{id}"))
      ([], KnfLeftValue::Ident(name))
    }
    FieldAccess(lval, fname) => {
      let (stmts_lval, expr_lval) = self.left_value_to_expr(lval)
      let ty_lval = self.type_to_knf(lval.ty)
      let sname = self.expr_to_knf_name_opt(expr_lval, ty_lval, stmts_lval)
      (stmts_lval, KnfLeftValue::FieldAcc(sname, fname))
    }
  }
}

///|
fn Context::left_value_to_expr(
  self : Self,
  left_value : @typecheck.LeftValue,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match left_value.kind {
    ArrayAccess(lval, idx) => {
      let (stmts_lval, expr_lval) = self.left_value_to_expr(lval)
      let (stmts_idx, expr_idx) = self.expr_to_knf(idx)
      let ty_idx = self.typekind_to_knf(idx.ty)
      let name_idx = self.expr_to_knf_name_opt(expr_idx, ty_idx, stmts_idx)
      let ty_lval = self.type_to_knf(lval.ty)
      let name_lval = self.expr_to_knf_name_opt(expr_lval, ty_lval, stmts_lval)
      (stmts_lval.add(stmts_idx), KnfExpr::ArrayAccess(name_lval, name_idx))
    }
    Ident(id) => {
      let (name, _) = self
        .lookup_name(id)
        .or_error(KnfTransformError("unable to find \{id}"))
      ([], KnfExpr::Ident(name))
    }
    FieldAccess(lval, fname) => {
      let (stmts_lval, expr_lval) = self.left_value_to_expr(lval)
      let ty_lval = self.type_to_knf(lval.ty)
      let name_lval = self.expr_to_knf_name_opt(expr_lval, ty_lval, stmts_lval)
      (stmts_lval, KnfExpr::FieldAccess(name_lval, fname))
    }
  }
}
