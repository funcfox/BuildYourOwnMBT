///|
pub fn Context::while_stmt_to_knf(
  self : Context,
  while_stmt : @typecheck.WhileStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  ignore(self)
  ignore(while_stmt)
  raise KnfTransformError("while_stmt_to_knf not implemented")
}
