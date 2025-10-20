///|
pub(all) struct LocalFunction {
  fname : String
  param_list : Array[(String, Type)]
  ret_ty : Type
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_local_function(
  self : Context,
  func : @parser.LocalFunction,
) -> LocalFunction raise TypeCheckError {
  ignore(self)
  ignore(func)
  raise TypeCheckError("check_local_function not implemented")
}
