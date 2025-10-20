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
  ignore(self)
  ignore(top_let)
  raise TypeCheckError("check_top_let not implemented")
}
