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
  ignore(self)
  ignore(while_stmt)
  raise TypeCheckError("check_while_stmt not implemented")
}
