///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
} derive(Show, Eq)

///|
pub fn parse_block_expr(
  tokens : ArrayView[Token],
) -> (BlockExpr, ArrayView[Token]) raise ParseError {
  let mut rest = match tokens {
    [{ kind: Bracket('{') }, .. rst] => rst
    _ => raise ParseError("expected '{'")
  }
  let stmts = []
  while !(rest is [{ kind: Bracket('}') }, ..]) {
    let (stmt, rest_) = parse_stmt(rest)
    stmts.push(stmt)
    rest = rest_
  }
  rest = match rest {
    [{ kind: Bracket('}') }, .. rst] => rst
    _ => raise ParseError("expected '}'")
  }
  (BlockExpr::{ stmts, }, rest)
}

// test "test block expr" {
//   let inp =
//     #|{
//     #|  let c = Circle::{ radius: 2.0 };
//     // #|  let r = Rectangle::{ a: 3.0, b: 4.0, c: 5.0 };
//     // #|  let ac = area_circle(c);
//     // #|  let ar = area_rectangle(r);
//     // #|  if ac > ar {
//     // #|    print_str("Circle area is larger");
//     // #|  } else {
//     // #|    print_str("Rectangle area is larger");
//     // #|  };
//     #|}
//   let tokens = @lexer.tokenize(inp)
//   println(tokens)
//   let (block, rest) = parse_block_expr(tokens)
//   println(block)
//   // println(rest)
// }