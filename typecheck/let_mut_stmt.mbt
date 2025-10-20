///|
pub(all) struct LetMutStmt {
  name : String
  ty : Type
  expr : Expr
} derive(Show)

///|
pub fn Context::check_let_mut_stmt(
  self : Context,
  stmt : @parser.LetMutStmt,
) -> LetMutStmt raise TypeCheckError {
  ignore(self)
  ignore(stmt)
  raise TypeCheckError("check_let_mut_stmt not implemented")
}
