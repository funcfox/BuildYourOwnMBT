///|
pub fn Context::block_codegen(
  self : Self,
  block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  let current_func = self.builder.getInsertFunction()
  let block_bb = current_func.addBasicBlock()
  let after_bb = current_func.addBasicBlock()
  self.builder.createBr(block_bb) |> ignore
  self.builder.setInsertPoint(block_bb)
  let (prev_stmts, last_stmt) = match block.stmts {
    [] => ([], None)
    stmts => {
      let len = stmts.length()
      (stmts[:len - 1].to_array(), Some(stmts[len - 1]))
    }
  }
  for stmt in prev_stmts.iter() {
    self.stmt_codegen(stmt)
  }
  let ret_value = match last_stmt {
    None => None
    Some(stmt) => match stmt {
      ExprStmt(expr) => self.expr_codegen(expr)
      // Return(expr) => self.expr_codegen(expr) // TODO: check impl
      // ReturnUnit => None
      _ => {
        self.stmt_codegen(stmt)
        None
      }
    }
  }
  self.builder.createBr(after_bb) |> ignore
  self.builder.setInsertPoint(after_bb)
  ret_value
}
