///|
pub(all) struct LetStmt {
  pattern : Pattern
  ty : TypeKind
  expr : Expr
} derive(Show)

///|
pub(all) struct Pattern {
  kind : PatternKind
} derive(Show, Eq)

///|
pub(all) enum PatternKind {
  Wildcard
  Ident(String)
  Tuple(Array[Pattern])
} derive(Show, Eq)

///|
pub fn Context::check_let_stmt(
  self : Context,
  let_stmt : @parser.LetStmt,
) -> LetStmt raise TypeCheckError {
  ignore(self)
  ignore(let_stmt)
  raise TypeCheckError("check_let_stmt not implemented")
}

