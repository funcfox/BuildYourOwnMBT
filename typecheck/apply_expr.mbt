///|
pub(all) struct ApplyExpr {
  kind : ApplyExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  Call(ApplyExpr, Array[Expr])
} derive(Show)

///|
pub fn Context::check_apply_expr(
  self : Self,
  apply_expr : @parser.ApplyExpr,
) -> ApplyExpr raise TypeCheckError {
  ignore(self)
  ignore(apply_expr)
  raise TypeCheckError("check_apply_expr not implemented")
}
