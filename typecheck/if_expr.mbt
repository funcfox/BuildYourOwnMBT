///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_if_expr(
  self : Context,
  if_expr : @parser.IfExpr,
) -> IfExpr raise TypeCheckError {
  ignore(self)
  ignore(if_expr)
  raise TypeCheckError("check_if_expr not implemented")
}
