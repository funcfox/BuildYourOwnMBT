///|
pub(all) struct WhileStmt {
  cond : Expr
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_while_stmt(
  tokens : ArrayView[Token],
) -> (WhileStmt, ArrayView[Token]) raise ParseError {
  let rest = match tokens {
    [{ kind: Keyword(While) }, .. rst] => rst
    _ => raise ParseError("expected 'while'")
  }
  let (cond, rest) = parse_expr(rest)
  let (body, rest) = parse_block_expr(rest)
  (WhileStmt::{ cond, body }, rest)
}
