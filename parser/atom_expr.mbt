///|
pub(all) struct AtomExpr {
  kind : AtomExprKind
} derive(Show, Eq)

///|
pub(all) enum AtomExprKind {
  Int(Int) // 1, 42, etc
  Double(Double) // 1.0, 3.14, etc
  Bool(Bool) // true | false
  String(String) // "hello", etc
  Ident(String) // var
  Unit // ()
  Paren(Expr) // (expr)
  Tuple(Array[Expr]) // (expr, expr, ...)
  Array(Array[Expr]) // [expr, expr, ...]
  ArrayMake(Expr, Expr) // Array::make(size, init)
  StructConstruct(StructConstructExpr) // StructName::{ field: expr, ... }
} derive(Show, Eq)

///|
pub fn parse_atom_expr(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  match tokens {
    [{ kind: Int(n) }, .. rest] =>
      (AtomExpr::{ kind: AtomExprKind::Int(n) }, rest)
    [{ kind: Double(n) }, .. rest] =>
      (AtomExpr::{ kind: AtomExprKind::Double(n) }, rest)
    [{ kind: Bool(b) }, .. rest] =>
      (AtomExpr::{ kind: AtomExprKind::Bool(b) }, rest)
    [{ kind: String(s) }, .. rest] =>
      (AtomExpr::{ kind: AtomExprKind::String(s) }, rest)
    [{ kind: Lower(name) }, .. rest] =>
      (AtomExpr::{ kind: AtomExprKind::Ident(name) }, rest)
    _ => raise ParseError("Expected Atom")
  }
}
