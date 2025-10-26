///|
pub(all) struct Stmt {
  kind : StmtKind
} derive(Show)

///|
pub(all) enum StmtKind {
  LetStmt(LetStmt)
  LetMutStmt(LetMutStmt)
  AssignStmt(AssignStmt)
  WhileStmt(WhileStmt)
  ExprStmt(Expr)
  ReturnStmt(Expr?)
  LocalFunction(LocalFunction)
} derive(Show)

///|
pub fn Context::check_stmt(
  self : Context,
  stmt : @parser.Stmt,
) -> Stmt raise TypeCheckError {
  match stmt.kind {
    ReturnStmt(ret_expr) =>
      match (ret_expr, self.current_func_ret_ty) {
        (Some(re), Some(tk)) => {
          let re = self.check_expr(re)
          if self.is_type_compatible(re.ty, tk) {
            Stmt::{ kind: StmtKind::ReturnStmt(Some(re)) }
          } else {
            raise TypeCheckError(
              "[Context::check_stmt] 'return [\{re.kind}];' must match return type \{tk}",
            )
          }
        }
        (None, Some(tk)) =>
          if self.is_type_compatible(tk, Unit) {
            Stmt::{ kind: StmtKind::ReturnStmt(None) }
          } else {
            raise TypeCheckError(
              "[Context::check_stmt] 'return ;' must have Unit return type",
            )
          }
        _ =>
          raise TypeCheckError(
            "[Context::check_stmt] 'return' is out of function",
          )
      }
    ExprStmt(expr) => Stmt::{ kind: StmtKind::ExprStmt(self.check_expr(expr)) }
    WhileStmt(ws) =>
      Stmt::{ kind: StmtKind::WhileStmt(self.check_while_stmt(ws)) }
    AssignStmt(assign_stmt) =>
      Stmt::{ kind: StmtKind::AssignStmt(self.check_assign_stmt(assign_stmt)) }
    LetMutStmt(lm_stmt) =>
      Stmt::{ kind: StmtKind::LetMutStmt(self.check_let_mut_stmt(lm_stmt)) }
    LetStmt(lt_stmt) =>
      Stmt::{ kind: StmtKind::LetStmt(self.check_let_stmt(lt_stmt)) }
    LocalFunction(lf) =>
      Stmt::{ kind: StmtKind::LocalFunction(self.check_local_function(lf)) }
  }
}
