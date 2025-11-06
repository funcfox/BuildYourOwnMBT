///|
pub fn Context::if_codegen(
  self : Self,
  cond : @knf.KnfExpr,
  then_block : @knf.KnfBlock,
  else_block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  let current_func = self.builder.getInsertFunction()
  let cond_value = self
    .expr_codegen(cond)
    .or_error(CodegenError("unable to gen code for if condition"))
  let then_bb = current_func.addBasicBlock()
  let else_bb = current_func.addBasicBlock()
  let merge_bb = current_func.addBasicBlock()
  self.builder.createCondBr(cond_value, then_bb, else_bb) |> ignore
  self.builder.setInsertPoint(then_bb)
  let then_value = self.if_block_codegen(then_block)
  let then_terminator = self.builder.getInsertBlock().getTerminator()
  if then_terminator is None {
    self.builder.createBr(merge_bb) |> ignore
  }
  self.builder.setInsertPoint(else_bb)
  let else_value = self.if_block_codegen(else_block)
  let else_terminator = self.builder.getInsertBlock().getTerminator()
  if else_terminator is None {
    self.builder.createBr(merge_bb) |> ignore
  }
  self.builder.setInsertPoint(merge_bb)
  if then_terminator is Some(_) && else_terminator is Some(_) {
    // remove merge_bb
    merge_bb.removeFromParent() |> ignore
    None
  } else {
    // create PHI node if needed
    match (then_value, else_value) {
      (Some(t_val), Some(e_val)) => {
        let phi_node = self.builder.createPHI(t_val.getType())
        phi_node.addIncoming(t_val, then_bb) |> ignore
        phi_node.addIncoming(e_val, else_bb) |> ignore
        Some(phi_node)
      }
      (Some(t_val), None) => Some(t_val)
      (None, Some(e_val)) => Some(e_val)
      (None, None) => None
    }
  }
  // match (then_terminator, else_terminator) {
  //   (Some(_), Some(_)) => {
  //     // remove merge_bb
  //     merge_bb.removeFromParent() |> ignore
  //     None
  //   }
  //   (Some(_), None) => else_value
  //   (None, Some(_)) => then_value
  //   (None, None) => {
  //     // create PHI node if needed
  //     ...
  //   }
  // }
}

///|
fn Context::if_block_codegen(
  self : Self,
  block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
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
    Some(stmt) =>
      match stmt {
        ExprStmt(expr) => self.expr_codegen(expr)
        // Return(expr) => self.expr_codegen(expr) // TODO: check impl
        // ReturnUnit => None
        _ => {
          self.stmt_codegen(stmt)
          None
        }
      }
  }
  ret_value
}
