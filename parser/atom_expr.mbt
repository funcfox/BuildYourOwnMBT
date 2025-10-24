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
    [{ kind: Bracket('(') }, ..] => parse_paren_expr(tokens)
    _ => raise ParseError("Expected Atom")
  }
}

///|
fn parse_paren_expr(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  let mut rest = match tokens {
    [{ kind: Bracket('(') }, .. rest] => rest
    _ => raise ParseError("expected a '('")
  }
  let inner = []
  while !(rest is [{ kind: Bracket(')') }, ..]) {
    let (expr, rest_) = parse_expr(rest)
    rest = rest_
    inner.push(expr)
    // rest = skip_if_comma(rest)
    rest = match rest {
      [{ kind: Symbol(",") }, .. rst] => rst
      _ => rest
    }
  }
  rest = match rest {
    [{ kind: Bracket(')') }, .. rst] => rst
    _ => raise ParseError("expected a ')'")
  }
  let result = match inner {
    [] => AtomExprKind::Unit
    [e] => AtomExprKind::Paren(e)
    _ => AtomExprKind::Tuple(inner)
  }
  (AtomExpr::{ kind: result }, rest)
}

// ///|
// fn skip_if_comma(tokens : ArrayView[Token]) -> ArrayView[Token] {
//   match tokens {
//     [{ kind: Symbol(",") }, .. rest] => rest
//     _ => tokens
//   }
// }
