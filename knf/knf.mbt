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
  // trans struct_defs
  let struct_defs = Map::new(capacity=prog.struct_defs.length())
  for item in prog.struct_defs.iter() {
    let df = self.struct_def_to_knf(item.1)
    struct_defs.set(item.0, df)
  }
  // println("trans struct_defs CMPL")
  // trans top_lets
  let top_lets = Map::new(capacity=prog.top_lets.length())
  for item in prog.top_lets.iter() {
    let tl = self.top_let_to_knf(item.1)
    top_lets.set(item.0, tl)
  }
  // println("trans top_lets CMPL")
  // trans top functions
  let functions = Map::new(capacity=prog.top_functions.length())
  for item in prog.top_functions.iter() {
    let tf = self.top_function_to_knf(item.1)
    functions.set(item.0, tf)
  }
  // println("trans top functions CMPL")
  KnfProgram::{ top_lets, struct_defs, functions }
}

///|
pub fn knf_transform(
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  let context = Context::new()
  context.globals.set("print_int", Function([Int], Unit))
  // println("start prog_to_knf")
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
