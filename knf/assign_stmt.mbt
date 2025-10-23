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
  ignore(self)
  ignore(assign_stmt)
  raise KnfTransformError("assign_stmt_to_knf not implemented")
}
