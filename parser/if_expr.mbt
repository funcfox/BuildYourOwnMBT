///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
} derive(Show, Eq)

///|
pub fn parse_if_expr(
  tokens : ArrayView[Token],
) -> (IfExpr, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  let rest = match tokens {
    [{ kind: Keyword(If) }, .. rst] => rst
    _ => raise ParseError("expected 'if'")
  }
  let (cond, rest) = parse_expr(rest)
  let (then_block, rest) = parse_block_expr(rest)
  match rest {
    [{ kind: Keyword(Else) }, .. rst] =>
      match rst {
        [{ kind: Keyword(If) }, ..] => {
          let (else_block, r) = parse_if_expr(rst)
          (IfExpr::{ cond, then_block, else_block: Some(Left(else_block)) }, r)
        }
        _ => {
          let (else_block, r) = parse_block_expr(rst)
          (IfExpr::{ cond, then_block, else_block: Some(Right(else_block)) }, r)
        }
      }
    _ => (IfExpr::{ cond, then_block, else_block: None }, rest)
  }
}
