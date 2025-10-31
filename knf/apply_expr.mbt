///|
pub fn Context::apply_expr_to_knf(
  self : Context,
  apply_expr : @typecheck.ApplyExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match apply_expr.kind {
    FieldAccess(app_expr, name) => {
      let (stmts_app, expr_app) = self.apply_expr_to_knf(app_expr)
      let ty_app = self.typekind_to_knf(app_expr.ty)
      let name_app = self.expr_to_knf_name_opt(expr_app, ty_app, stmts_app)
      let result = KnfExpr::FieldAccess(name_app, name)
      (stmts_app, result)
    }
    ArrayAccess(app_expr, idx_expr) => {
      let (stmts_idx, expr_idx) = self.expr_to_knf(idx_expr)
      let (stmts_app, expr_app) = self.apply_expr_to_knf(app_expr)
      let ty_idx = self.typekind_to_knf(idx_expr.ty)
      let ty_app = self.typekind_to_knf(app_expr.ty)
      let name_idx = self.expr_to_knf_name_opt(expr_idx, ty_idx, stmts_idx)
      let name_app = self.expr_to_knf_name_opt(expr_app, ty_app, stmts_app)
      let result = ArrayAccess(name_app, name_idx)
      (stmts_app.add(stmts_idx), result)
    }
    AtomExpr(atom_expr) => self.atom_expr_to_knf(atom_expr)
    Call(app_expr, args) => {
      let (stmts_app, expr_app) = self.apply_expr_to_knf(app_expr)
      let ty_app = self.typekind_to_knf(app_expr.ty)
      let name_app = self.expr_to_knf_name_opt(expr_app, ty_app, stmts_app)
      let stmts_args = []
      let name_args = []
      for arg in args {
        let (stmts_arg, expr_arg) = self.expr_to_knf(arg)
        let ty = self.typekind_to_knf(arg.ty)
        let name_arg = self.expr_to_knf_name_opt(expr_arg, ty, stmts_arg)
        stmts_args.append(stmts_arg)
        name_args.push(name_arg)
      }
      (stmts_app.add(stmts_args), KnfExpr::Call(name_app, name_args))
    }
  }
}

///|
fn Context::expr_to_knf_name_opt(
  self : Self,
  expr : KnfExpr,
  ty : Type,
  stmts : Array[KnfStmt],
) -> Name {
  if expr is Ident(name) {
    name
  } else {
    self.expr_to_knf_name(expr, ty, stmts)
  }
}
