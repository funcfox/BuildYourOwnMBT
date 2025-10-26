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
  self.enter_scope()
  // impl
  if block_expr.stmts.is_empty() {
    return BlockExpr::{ stmts: [], ty: Unit }
  }
  let stmts = block_expr.stmts.map(fn(stmt) { self.check_stmt(stmt) })
  let last_stmt = stmts
    .last()
    .or_error(
      TypeCheckError("[Context::check_block_expr] must have at least one elem"),
    )
  let ret_ty = match last_stmt.kind {
    ExprStmt(expr) => self.get_typekind(expr.ty)
    _ => Unit
  }
  self.exit_scope()
  BlockExpr::{ stmts, ty: ret_ty }
}
