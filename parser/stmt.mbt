///|
pub(all) struct Stmt {
  kind : StmtKind
} derive(Show, Eq)

///|
pub(all) enum StmtKind {
  LetStmt(LetStmt)
  LetMutStmt(LetMutStmt)
  AssignStmt(AssignStmt)
  WhileStmt(WhileStmt)
  ExprStmt(Expr)
  ReturnStmt(Expr?)
  LocalFunction(LocalFunction)
} derive(Show, Eq)

///|
pub fn parse_stmt(
  tokens : ArrayView[Token],
) -> (Stmt, ArrayView[Token]) raise ParseError {
  let (kind, rest) = match tokens {
    [{ kind: Keyword(Let) }, { kind: Keyword(Mut) }, ..] => {
      let (let_mut_stmt, rest) = parse_let_mut_stmt(tokens)
      (LetMutStmt(let_mut_stmt), rest)
    }
    [{ kind: Keyword(Let) }, ..] => {
      let (let_stmt, rest) = parse_let_stmt(tokens)
      (LetStmt(let_stmt), rest)
    }
    [{ kind: Keyword(Return) }, .. rest] =>
      match rest {
        // [{ kind: Symbol(";") }, .. rst] => (StmtKind::ReturnStmt(None), rest)
        [{ kind: Symbol(";") }, .. rst] => (StmtKind::ReturnStmt(None), rst)
        _ => {
          let (expr, rst_) = parse_expr(rest)
          let rst_ = match rst_ {
            [{ kind: Symbol(";") }, .. r] => r
            _ => raise ParseError("expected ';'")
          }
          (StmtKind::ReturnStmt(Some(expr)), rst_)
        }
      }
    _ => _parse_assign_stmt(tokens) catch { _ => _parse_expr(tokens) }
  }
  (Stmt::{ kind, }, rest)
}

///|
fn _parse_assign_stmt(
  tokens : ArrayView[Token],
) -> (StmtKind, ArrayView[Token]) raise ParseError {
  let (stmt, rest) = parse_assign_stmt(tokens)
  (StmtKind::AssignStmt(stmt), rest)
}

///|
fn _parse_expr(
  tokens : ArrayView[Token],
) -> (StmtKind, ArrayView[Token]) raise ParseError {
  let (expr, rest) = parse_expr(tokens)
  let rest = match rest {
    [{ kind: Symbol(";") }, .. rst] => rst
    [{ kind: Bracket('}') }, ..] as rst => rst
    _ => raise ParseError("expected ';'")
  }
  (StmtKind::ExprStmt(expr), rest)
}
