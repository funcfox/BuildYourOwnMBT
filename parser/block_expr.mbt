///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
} derive(Show, Eq)

///|
pub fn parse_block_expr(
  tokens : ArrayView[Token],
) -> (BlockExpr, ArrayView[Token]) raise ParseError {
  let mut rest = match tokens {
    [{ kind: Bracket('{') }, .. rst] => rst
    _ => raise ParseError("expected '{'")
  }
  let stmts = []
  while !(rest is [{ kind: Bracket('}') }, ..]) {
    let (stmt, rest_) = parse_stmt(rest)
    stmts.push(stmt)
    rest = rest_
  }
  rest = match rest {
    [{ kind: Bracket('}') }, .. rst] => rst
    _ => raise ParseError("expected '}'")
  }
  (BlockExpr::{ stmts, }, rest)
}
