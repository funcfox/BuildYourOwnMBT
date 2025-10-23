///|
pub fn Context::apply_expr_to_knf(
  self : Context,
  apply_expr : @typecheck.ApplyExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  ignore(self)
  ignore(apply_expr)
  raise KnfTransformError("apply_expr_to_knf not implemented")
}
