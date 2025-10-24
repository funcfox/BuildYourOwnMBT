///|
pub(all) struct ApplyExpr {
  kind : ApplyExprKind
} derive(Show, Eq)

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  Call(ApplyExpr, Array[Expr])
} derive(Show, Eq)

///|
pub fn parse_apply_expr(
  tokens : ArrayView[Token],
) -> (ApplyExpr, ArrayView[Token]) raise ParseError {
  let (atm, rest) = parse_atom_expr(tokens)
  let mut app_expr = ApplyExpr::{ kind: ApplyExprKind::AtomExpr(atm) }
  let mut rest = rest
  // parse array access expr
  while rest
        is [
          { kind: Bracket('[') }
          | { kind: Bracket('(') }
          | { kind: Symbol(".") },
          ..,
        ] {
    if rest is [{ kind: Bracket('[') }, ..] {
      let (acc_expr, rest_) = parse_array_access_expr(rest)
      rest = rest_
      app_expr = ApplyExpr::{
        kind: ApplyExprKind::ArrayAccess(app_expr, acc_expr),
      }
    } else if rest is [{ kind: Bracket('(') }, ..] {
      let (arg_exprs, rest_) = parse_expr_list(rest)
      rest = rest_
      app_expr = ApplyExpr::{ kind: ApplyExprKind::Call(app_expr, arg_exprs) }
    } else if rest is [{ kind: Symbol(".") }, ..] {
      let (app_expr_, rest_) = match rest {
        [{ kind: Symbol(".") }, { kind: Lower(fname) }, .. rst] =>
          (
            ApplyExpr::{ kind: ApplyExprKind::FieldAccess(app_expr, fname) },
            rst,
          )
        _ => raise ParseError("expected '.[lower_name]'")
      }
      rest = rest_
      app_expr = app_expr_
    }
  }
  (app_expr, rest)
}

///|
fn parse_array_access_expr(
  tokens : ArrayView[Token],
) -> (Expr, ArrayView[Token]) raise ParseError {
  let rest = match tokens {
    [{ kind: Bracket('[') }, .. rst] => rst
    _ => raise ParseError("Expected '['")
  }
  let (acc_expr, rest) = parse_expr(rest)
  let rest = match rest {
    [{ kind: Bracket(']') }, .. rst] => rst
    _ => raise ParseError("Expected ']'")
  }
  (acc_expr, rest)
}
