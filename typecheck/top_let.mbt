///|
pub(all) struct TopLet {
  name : String
  ty : Type
  expr : Expr
} derive(Show)

///|
pub fn Context::check_top_let(
  self : Context,
  top_let : @parser.TopLet,
) -> TopLet raise TypeCheckError {
  // ignore(self)
  // ignore(top_let)
  // raise TypeCheckError("check_top_let not implemented")
  let name = top_let.name
  let expr = self.check_expr(top_let.expr)
  let kind = match top_let.ty {
    Some(t) => {
      let tt = self.check_parser_type(t)
      if self.is_type_compatible(tt.kind, expr.ty) {
        expr.ty
      } else {
        raise TypeCheckError(
          "[Context::check_top_let] sig[\{tt.kind}] not compat expr[\{expr.ty}]",
        )
      }
    }
    None => self.get_typekind(expr.ty)
  }
  let ty = Type::{ kind, mutable: false }
  self.type_env.set(name, ty)
  TopLet::{ name, ty, expr }
}
