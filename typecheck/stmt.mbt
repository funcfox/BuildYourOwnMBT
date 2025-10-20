///|
pub(all) struct Stmt {
  kind : StmtKind
} derive(Show)

///|
pub(all) enum StmtKind {
  LetStmt(LetStmt)
  LetMutStmt(LetMutStmt)
  AssignStmt(AssignStmt)
  WhileStmt(WhileStmt)
  ExprStmt(Expr)
  ReturnStmt(Expr?)
  LocalFunction(LocalFunction)
} derive(Show)

///|
pub fn Context::check_stmt(
  self : Context,
  stmt : @parser.Stmt,
) -> Stmt raise TypeCheckError {
  ignore(self)
  ignore(stmt)
  raise TypeCheckError("check_stmt not implemented")
}
