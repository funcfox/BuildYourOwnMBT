///|
pub(all) struct WhileStmt {
  cond : Expr
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_while_stmt(
  self : Context,
  while_stmt : @parser.WhileStmt,
) -> WhileStmt raise TypeCheckError {
  let cond = self.check_expr(while_stmt.cond)
  if !self.is_type_compatible(Bool, cond.ty) {
    raise TypeCheckError("[Context::check_while_stmt] cond's type must be Bool")
  }
  let body = self.check_block_expr(while_stmt.body)
  WhileStmt::{ cond, body }
}
