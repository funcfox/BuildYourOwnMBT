///|
pub fn typecheck(program : @parser.Program) -> Program raise TypeCheckError {
  let ctx = Context::new()
  let checked_program = ctx.check_program(program)
  ctx.substitute_type_var(checked_program)
}

///|
pub fn Context::substitute_type_var(
  self : Context,
  program : Program,
) -> Program raise TypeCheckError {
  ignore(self)
  ignore(program)
  raise TypeCheckError("Substitute type variable not implemented yet")
}
