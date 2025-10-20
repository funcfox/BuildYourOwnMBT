///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_block_expr(
  self : Context,
  block_expr : @parser.BlockExpr,
) -> BlockExpr raise TypeCheckError {
  ignore(self)
  ignore(block_expr)
  raise TypeCheckError("check_block_expr not implemented")
}
