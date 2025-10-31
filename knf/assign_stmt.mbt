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
  let (stmts, expr) = self.expr_to_knf(assign_stmt.expr)
  let ty = self.typekind_to_knf(assign_stmt.expr.ty)
  let stmts_assign = match assign_stmt.op {
    DivAssign | MultAssign | MinusAssign | PlusAssign | ModAssign => {
      let op = match assign_stmt.op {
        DivAssign => BinaryOp::Div
        MultAssign => BinaryOp::Mul
        MinusAssign => BinaryOp::Sub
        PlusAssign => BinaryOp::Add
        ModAssign => BinaryOp::Mod
        _ =>
          raise KnfTransformError(
            "this shouldn't be happen in Context::assign_stmt_to_knf",
          )
      }
      let lexpr = self.left_value_to_expr(assign_stmt.left_value)
      let stmt_before_assign = []
      let name_left = self.expr_to_knf_name_opt(lexpr, ty, stmt_before_assign)
      let name_right = self.expr_to_knf_name_opt(expr, ty, stmt_before_assign)
      let name_binary = self.add_temp(ty)
      stmt_before_assign.push(
        Let(name_binary, ty, Binary(op, name_left, name_right)),
      )
      let stmt_assign = self.naive_assign_to_knf(
        assign_stmt.left_value,
        Ident(name_binary),
      )
      // println(stmt_assign)
      stmt_before_assign.add(stmt_assign)
    }
    Assign => self.naive_assign_to_knf(assign_stmt.left_value, expr)
  }
  stmts.add(stmts_assign)
}

///|
fn Context::left_value_to_expr(
  self : Self,
  left_value : @typecheck.LeftValue,
) -> KnfExpr raise KnfTransformError {
  match left_value.kind {
    ArrayAccess(_) => ...
    Ident(name) => {
      let (name, _) = self
        .lookup_name(name)
        .or_error(KnfTransformError("unable to find name in context"))
      Ident(name)
    }
    FieldAccess(_) => ...
  }
}

///|
fn Context::naive_assign_to_knf(
  self : Self,
  left_value : @typecheck.LeftValue,
  // ty : Type,
  expr : KnfExpr,
) -> Array[KnfStmt] raise KnfTransformError {
  match left_value.kind {
    ArrayAccess(_) =>
      // ArrayPut()
      ...
    Ident(name) => {
      let (name, _) = self
        .lookup_name(name)
        .or_error(KnfTransformError("unable to find name \{name}"))
      // [Let(name, ty, expr)]
      [Assign(name, expr)]
    }
    FieldAccess(_) => ...
  }
}

///|
fn Context::assign_get_left_value_name(
  self : Self,
  left_value : @typecheck.LeftValue,
) -> (Array[KnfStmt], Name) raise KnfTransformError {
  // let stmts = []
  match left_value.kind {
    ArrayAccess(lval, idx_expr) => {
      // let (stmt_idx, expr_idx) = self.expr_to_knf(idx_expr)
      // let ty = self.typekind_to_knf(idx_expr.ty)
      // let name_idx = self.expr_to_knf_name_opt(expr_idx, ty, stmt_idx)
      // let (stmt_lval, name_lval) = self.assign_get_left_value_name(lval)
      // let stmt_result = stmt_idx.add(stmt_lval)
      // let ty_result = if left_value.ty.kind is Array(ty_ret) {ty_ret} else {raise KnfTransformError("")}
      ...
    }
    Ident(id) => {
      let (name, _) = self
        .lookup_name(id)
        .or_error(KnfTransformError("unable to find \{id}"))
      ([], name)
    }
    FieldAccess(_) => ...
  }
}
