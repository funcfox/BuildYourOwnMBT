///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show, Eq)

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq)

///|
fn AssignOp::from_tok_assign_op(op : @lexer.AssignOp) -> AssignOp {
  match op {
    Assign => Assign
    PlusAssign => PlusAssign
    MinusAssign => MinusAssign
    MultAssign => MultAssign
    DivAssign => DivAssign
    ModAssign => ModAssign
  }
}

///|
pub fn parse_assign_stmt(
  tokens : ArrayView[Token],
) -> (AssignStmt, ArrayView[Token]) raise ParseError {
  // assign_stmt ::= left_value assign_op expr ";"
  let (left_value, rest) = parse_left_value(tokens)
  let (op, rest) = match rest {
    [{ kind: AssignOp(aop) }, .. rst] => (aop, rst)
    _ => raise ParseError("expected AssignOp")
  }
  let (expr, rest) = parse_expr(rest)
  let op = AssignOp::from_tok_assign_op(op)
  let rest = match rest {
    [{ kind: Symbol(";") }, .. rst] => rst
    _ => raise ParseError("expected ';'")
  }
  (AssignStmt::{ left_value, op, expr }, rest)
}
