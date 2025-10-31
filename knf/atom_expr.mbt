///|
pub fn Context::atom_expr_to_knf(
  self : Context,
  atom_expr : @typecheck.AtomExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match atom_expr.kind {
    ArrayMake(size, init) => {
      let (stmts_size, expr_size) = self.expr_to_knf(size)
      let (stmts_init, expr_init) = self.expr_to_knf(init)
      let name_size = if expr_size is Ident(name) {
        name
      } else {
        let ty = self.typekind_to_knf(size.ty)
        let name = self.add_temp(ty)
        stmts_init.push(Let(name, ty, expr_size))
        name
      }
      let name_init = if expr_init is Ident(name) {
        name
      } else {
        let ty = self.typekind_to_knf(init.ty)
        let name = self.add_temp(ty)
        stmts_init.push(Let(name, ty, expr_init))
        name
      }
      ([..stmts_size, ..stmts_init], ArrayMake(name_size, name_init))
    }
    Array(expr_list) => {
      let stmts = []
      let names = []
      let ret_ty = self.typekind_to_knf(atom_expr.ty)
      for expr in expr_list {
        let (stmts_, expr_) = self.expr_to_knf(expr)
        stmts.append(stmts_)
        if expr_ is Ident(name) {
          names.push(name)
        } else {
          let ty = self.typekind_to_knf(expr.ty)
          let name = self.add_temp(ty)
          stmts.push(Let(name, ty, expr_))
          names.push(name)
        }
      }
      let res_expr = KnfExpr::ArrayLiteral(ret_ty, names)
      (stmts, res_expr)
    }
    Tuple(expr_list) => {
      let stmts = []
      let names = []
      for expr in expr_list {
        let (stmts_, expr_) = self.expr_to_knf(expr)
        stmts.append(stmts_)
        if expr_ is Ident(name) {
          names.push(name)
        } else {
          let ty = self.typekind_to_knf(expr.ty)
          let name = self.add_temp(ty)
          stmts.push(Let(name, ty, expr_))
          names.push(name)
        }
      }
      let res_expr = KnfExpr::TupleLiteral(names)
      (stmts, res_expr)
    }
    Paren(expr) => self.expr_to_knf(expr)
    Unit => ([], Unit)
    Ident(id) =>
      self
      .lookup_name(id)
      .map(fn(n) { ([], KnfExpr::Ident(n.0)) })
      .or_error(
        KnfTransformError(
          "[Context::atom_expr_to_knf] unable to find name \{id}",
        ),
      )
    String(s) => ([], String(s))
    Bool(b) => ([], Bool(b))
    Double(d) => ([], Double(d))
    Int(n) => ([], Int(n))
    StructConstruct(sc_expr) => {
      let stmts = []
      let field_names = []
      for field in sc_expr.fields {
        let (stmts_, expr_) = self.expr_to_knf(field.1)
        stmts.append(stmts_)
        let name = if expr_ is Ident(name) {
          name
        } else {
          let ty = self.typekind_to_knf(field.1.ty)
          let name = self.add_temp(ty)
          stmts.push(Let(name, ty, expr_))
          name
        }
        field_names.push((field.0, name))
      }
      let result = KnfExpr::CreateStruct(sc_expr.name, field_names)
      (stmts, result)
    }
  }
}

// fn Context::atom_expr_to_knf_expr_arr(self: Self, exprs: KnfExpr) ->
