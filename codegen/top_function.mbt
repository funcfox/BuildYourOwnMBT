///|
///
/// 注意区分main函数与其他函数的codegen。
pub fn Context::top_function_codegen(
  self : Self,
  func : @knf.KnfFunction,
) -> @llvm.Function raise {
  let func_gen = self.functions
    .get(func.name)
    .or_error(CodegenError("unable to find function \{func.name}"))
  let entry_bb = func_gen.addBasicBlock(name="entry")
  self.builder.setInsertPoint(entry_bb)
  // save name_types and name_values
  let saved_name_types = self.name_types.copy()
  let saved_name_values = self.name_values.copy()
  // add params
  for i, p in func.params.iter2() {
    self.name_types.set(p.0, p.1)
    self.name_values.set(
      p.0,
      func_gen
      .getArg(i + 1)
      .or_error(CodegenError("unable to get func arg \{i+1}")),
    )
  }
  let (body, last_stmt) = match func.body.stmts {
    [] => ([], None)
    stmts => {
      let len = stmts.length()
      (stmts[:len - 1].to_array(), Some(stmts[len - 1]))
    }
  }
  for stmt in body.iter() {
    self.stmt_codegen(stmt)
  }
  ///// process body CMPL
  self.function_return_codegen(last_stmt)
  // delete params
  // for p in func.params.iter() {
  //   self.name_types.remove(p.0)
  //   self.name_values.remove(p.0)
  // }
  // restore name_types and name_values
  for it in saved_name_types.iter() {
    self.name_types.set(it.0, it.1)
  }
  for it in saved_name_values.iter() {
    self.name_values.set(it.0, it.1)
  }
  func_gen
}

///|
fn Context::function_return_codegen(
  self : Self,
  stmt : @knf.KnfStmt?,
) -> Unit raise {
  match stmt {
    None | Some(ReturnUnit) => {
      let _ = self.builder.createRetVoid()
    }
    Some(stmt) =>
      match stmt {
        Return(expr) => {
          let expr = self
            .expr_codegen(expr)
            .or_error(CodegenError("unable to gen code of \{expr}"))
          let _ = self.builder.createRet(expr)
        }
        ExprStmt(expr) => {
          let expr = self
            .expr_codegen(expr)
          if expr is Some(ret_expr) {
            let _ = self.builder.createRet(ret_expr)  // TODO: check impl
          }
        }
        // _ =>
        //   raise CodegenError(
        //     "function body syntax error: need a Return or ExprStmt",
        //   )
        s => {
          self.stmt_codegen(s)
          let _ = self.builder.createRetVoid()
        }
      }
  }
}
