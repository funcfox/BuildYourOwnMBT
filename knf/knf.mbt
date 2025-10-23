///|
pub(all) struct KnfProgram {
  struct_defs : Map[String, KnfStructDef]
  top_lets : Map[String, KnfTopLet]
  functions : Map[String, KnfFunction]
}

///|
pub fn Context::program_to_knf(
  self : Context,
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  ignore(self)
  ignore(prog)
  raise KnfTransformError("program_to_knf not implemented")
}

///|
pub fn knf_transform(
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  let context = Context::new()
  context.globals.set("print_int", Function([Int], Unit))
  context.program_to_knf(prog)
}

///|
pub impl Show for KnfProgram with output(self, logger) {
  for _, struct_def in self.struct_defs {
    logger.write_object(struct_def)
    logger.write_char('\n')
  }
  for _, top_let in self.top_lets {
    logger.write_object(top_let)
    logger.write_char('\n')
  }
  for _, func in self.functions {
    logger.write_object(func)
    logger.write_char('\n')
  }
}
