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
pub fn parse_pattern(
  tokens : ArrayView[Token],
) -> (Pattern, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Wildcard }, .. rest] =>
      (Pattern::{ kind: PatternKind::Wildcard }, rest)
    [{ kind: Lower(ident) }, .. rest] =>
      (Pattern::{ kind: PatternKind::Ident(ident) }, rest)
    [{ kind: Bracket('(') }, .. rest] => {
      let mut rest = rest
      let inner = []
      while !(rest is [{ kind: Bracket(')') }, ..]) {
        let (pt, rest_) = parse_pattern(rest)
        rest = rest_
        inner.push(pt)
        rest = match rest {
          [{ kind: Symbol(",") }, .. rst] => rst
          _ => rest
        }
      }
      rest = match rest {
        [{ kind: Bracket(')') }, .. rst] => rst
        _ => raise ParseError("expected a ')'")
      }
      (Pattern::{ kind: PatternKind::Tuple(inner) }, rest)
    }
    _ => raise ParseError("unknown pattern: \{tokens[0]}")
  }
}
