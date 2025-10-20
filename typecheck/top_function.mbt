///|
pub(all) struct Param {
  name : String
  ty : TypeKind
} derive(Show)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : TypeKind
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_top_function(
  self : Context,
  func : @parser.TopFunction,
) -> TopFunction raise TypeCheckError {
  ignore(self)
  ignore(func)
  raise TypeCheckError("check_top_function not implemented")
}
