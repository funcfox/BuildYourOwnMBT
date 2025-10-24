///|
pub(all) struct LeftValue {
  kind : LeftValueKind
} derive(Show, Eq)

///|
pub(all) enum LeftValueKind {
  Ident(String)
  ArrayAccess(LeftValue, Expr)
  FieldAccess(LeftValue, String)
} derive(Show, Eq)

///|
pub fn parse_left_value(
  tokens : ArrayView[Token],
) -> (LeftValue, ArrayView[Token]) raise ParseError {
  let (lval, rest) = match tokens {
    [{ kind: Lower(ident) }, .. rest] =>
      (LeftValue::{ kind: LeftValueKind::Ident(ident) }, rest)
    _ => raise ParseError("unable to parse left value")
  }
  let mut lval = lval
  let mut rest = rest
  while rest is [{ kind: Bracket('[') } | { kind: Symbol(".") }, ..] {
    if rest is [{ kind: Bracket('[') }, ..] {
      let rst = match rest {
        [{ kind: Bracket('[') }, .. rst_] => rst_
        _ => raise ParseError("expected '['")
      }
      let (expr, rst) = parse_expr(rst)
      let rst = match rst {
        [{ kind: Bracket(']') }, .. rst_] => rst_
        _ => raise ParseError("expected ']'")
      }
      lval = LeftValue::{ kind: LeftValueKind::ArrayAccess(lval, expr) }
      rest = rst
    } else if rest is [{ kind: Symbol(".") }, ..] {
      let (lval_, rest_) = match rest {
        [{ kind: Symbol(".") }, { kind: Lower(fname) }, .. rst] =>
          (LeftValue::{ kind: LeftValueKind::FieldAccess(lval, fname) }, rst)
        _ => raise ParseError("expected '.[lower_name]'")
      }
      rest = rest_
      lval = lval_
    }
  }
  (lval, rest)
}
