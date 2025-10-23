///|
pub fn Context::atom_expr_to_knf(
  self : Context,
  atom_expr : @typecheck.AtomExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  ignore(self)
  ignore(atom_expr)
  raise KnfTransformError("atom_expr_to_knf not implemented")
}
