///|
pub fn Context::let_mut_stmt_to_knf(
  self : Context,
  let_mut_stmt : @typecheck.LetMutStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let (stmts, expr) = self.expr_to_knf(let_mut_stmt.expr)
  let ty = self.type_to_knf(let_mut_stmt.ty)
  let name = self.add_new_name(let_mut_stmt.name, ty)
  [..stmts, LetMut(name, ty, expr)]
}
