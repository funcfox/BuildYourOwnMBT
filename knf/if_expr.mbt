///|
pub fn Context::if_expr_to_knf(
  self : Context,
  if_expr : @typecheck.IfExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  ignore(self)
  ignore(if_expr)
  raise KnfTransformError("if_expr_to_knf not implemented")
}
