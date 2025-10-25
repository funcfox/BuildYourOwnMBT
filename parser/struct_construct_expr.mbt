///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show, Eq)

///|
pub fn parse_struct_construct(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  let (name, rest) = match tokens {
    [
      { kind: Upper(sname) },
      { kind: Symbol("::") },
      { kind: Bracket('{') },
      .. rest,
    ] => (sname, rest)
    _ => raise ParseError("expected '[Upper] :: {'")
  }
  let mut rest = rest
  let fields = []
  while !(rest is [{ kind: Bracket('}') }, ..]) {
    let (ident, expr, rest_) = match rest {
      [{ kind: Lower(name) }, { kind: Symbol(":") }, .. rst] => {
        let (e, r) = parse_expr(rst)
        (name, e, r)
      }
      _ => raise ParseError("expected '[ident] : [expr]'")
    }
    fields.push((ident, expr))
    rest = match rest_ {
      [{ kind: Symbol(",") }, .. r] => r
      _ => rest_
    }
  }
  rest = match rest {
    [{ kind: Bracket('}') }, .. r] => r
    _ => raise ParseError("expected '}'")
  }
  (
    AtomExpr::{
      kind: AtomExprKind::StructConstruct(StructConstructExpr::{ name, fields }),
    },
    rest,
  )
}
