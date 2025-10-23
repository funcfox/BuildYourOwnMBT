///|
pub(all) struct KnfTopLet {
  name : Name
  ty : Type
  expr : KnfExpr
}

///|
pub fn Context::top_let_to_knf(
  self : Context,
  top_let : @typecheck.TopLet,
) -> KnfTopLet raise KnfTransformError {
  ignore(self)
  ignore(top_let)
  raise KnfTransformError("top_let_to_knf not implemented")
}

///|
pub impl Show for KnfTopLet with output(self, logger) {
  let { name, ty, expr } = self
  logger.write_string("let \{name} : \{ty} = \{expr};")
}
