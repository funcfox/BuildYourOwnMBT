///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show)

///|
pub fn Context::check_struct_construct_expr(
  self : Self,
  sc_expr : @parser.StructConstructExpr,
) -> (AtomExprKind, TypeKind) raise TypeCheckError {
  ignore(self)
  ignore(sc_expr)
  raise TypeCheckError("check_struct_construct_expr not implemented")
}
