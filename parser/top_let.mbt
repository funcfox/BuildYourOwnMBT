///|
pub(all) struct TopLet {
  name : String
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_top_let(
  tokens : ArrayView[Token],
) -> (TopLet, ArrayView[Token]) raise ParseError {
  let (name, ty, rest) = match tokens {
    [
      { kind: Keyword(Let) },
      { kind: Lower(lname) },
      { kind: Symbol(":") },
      .. rst,
    ] => {
      let (ty, r) = parse_type(rst)
      (lname, Some(ty), r)
    }
    [{ kind: Keyword(Let) }, { kind: Lower(lname) }, .. rst] =>
      (lname, None, rst)
    _ => raise ParseError("expected 'let [ident] (: [type])?'")
  }
  let (expr, rest) = match rest {
    [{ kind: AssignOp(Assign) }, .. rst] => parse_expr(rst)
    _ => raise ParseError("expected '= [expr]'")
  }
  let rest = match rest {
    [{ kind: Symbol(";") }, .. r] => r
    _ => raise ParseError("expected ';'")
  }
  (TopLet::{ name, ty, expr }, rest)
}
