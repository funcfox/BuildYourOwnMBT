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
  (ApplyExpr::{ kind: ApplyExprKind::AtomExpr(atm) }, rest)
}
