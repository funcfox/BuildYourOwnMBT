///|
pub(all) struct LetStmt {
  pattern : Pattern
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_let_stmt(
  tokens : ArrayView[Token],
) -> (LetStmt, ArrayView[Token]) raise ParseError {
  // let_stmt ::= "let" pattern (":" type)? "=" expr ";"
  let rest = match tokens {
    [{ kind: Keyword(Let) }, .. rest] => rest
    _ => raise ParseError("expected 'let'")
  }
  let (pt, rest) = parse_pattern(rest)
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
  (LetStmt::{ pattern: pt, ty, expr }, rest)
}

///|
// test "test let" {
//   let code =
//     #| let c = Circle::{ radius: 2.0 };
//   let tokens = @lexer.tokenize(code)
//   println(tokens)
//   let (program, rest) = parse_let_stmt(tokens)
//   println(program)
//   println(rest)
// }
