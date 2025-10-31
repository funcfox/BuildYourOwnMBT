///|
pub fn Context::while_stmt_to_knf(
  self : Context,
  while_stmt : @typecheck.WhileStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let (stmts_cond, expr_cond) = self.expr_to_knf(while_stmt.cond)
  let cond_block = KnfBlock::{ stmts: [..stmts_cond, ExprStmt(expr_cond)], ty: Bool }
  let block = self.block_expr_to_knf(while_stmt.body)
  [KnfStmt::While(cond_block, block)]
}
