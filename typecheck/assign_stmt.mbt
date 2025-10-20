///|
pub(all) struct LeftValue {
  kind : LeftValueKind
  ty : Type
} derive(Show)

///|
pub(all) enum LeftValueKind {
  Ident(String)
  ArrayAccess(LeftValue, Expr)
  FieldAccess(LeftValue, String)
} derive(Show)

///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show)

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
pub fn AssignOp::from_parser_assign_op(op : @parser.AssignOp) -> AssignOp {
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
pub fn Context::check_assign_stmt(
  self : Context,
  assign_stmt : @parser.AssignStmt,
) -> AssignStmt raise TypeCheckError {
  ignore(self)
  ignore(assign_stmt)
  raise TypeCheckError("check_assign_stmt not implemented")
}
