///|
pub(all) struct LetMutStmt {
  name : String
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_let_mut_stmt(
  tokens : ArrayView[Token],
) -> (LetMutStmt, ArrayView[Token]) raise ParseError {
  // let_mut_stmt ::= "let" "mut" ident (":" type)? "=" expr ";"
  let rest = match tokens {
    [{ kind: Keyword(Let) }, .. rest] => rest
    _ => raise ParseError("expected 'let'")
  }
  let rest = match rest {
    [{ kind: Keyword(Mut) }, .. rest] => rest
    _ => raise ParseError("expected 'mut'")
  }
  // let (pt, rest) = parse_pattern(rest)
  let (name, rest) = match rest {
    [{ kind: Lower(id) }, .. rst] => (id, rst)
    _ => raise ParseError("expected ident")
  }
  let (ty, rest) = match rest {
    [{ kind: Symbol(":") }, .. rst] => {
      let (type_, rest_) = parse_type(rst)
      (Some(type_), rest_)
    }
    _ => (None, rest)
  }
  let rest = match rest {
    [{ kind: AssignOp(Assign) }, .. rst] => rst
    _ => raise ParseError("expected '='")
  }
  let (expr, rest) = parse_expr(rest)
  let rest = match rest {
    [{ kind: Symbol(";") }, .. rst] => rst
    _ => raise ParseError("expected ';'")
  }
  (LetMutStmt::{ name, ty, expr }, rest)
}
