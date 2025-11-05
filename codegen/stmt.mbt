///|
pub fn Context::stmt_codegen(self : Self, stmt : @knf.KnfStmt) -> Unit raise {
  match stmt {
    Let(name, ty, expr) => self.let_stmt_codegen(name, ty, expr)
    LetMut(name, ty, expr) => self.let_mut_stmt_codegen(name, ty, expr)
    Assign(name, expr) => self.assign_stmt_codegen(name, expr)
    ArrayPut(name, idx, expr) => self.array_put_codegen(name, idx, expr)
    StructFieldSet(_) =>
      raise CodegenError("StructFieldSet not implemented yet")
    While(_) => raise CodegenError("While not implemented yet")
    ExprStmt(_) => raise CodegenError("ExprStmt not implemented yet")
    Return(_) => raise CodegenError("Return with value not implemented yet")
    ReturnUnit => raise CodegenError("Return unit not implemented yet")
    ClosureDef(_) => raise CodegenError("ClosureDef not implemented yet")
  }
}

///|
pub fn Context::let_stmt_codegen(
  self : Self,
  name : @knf.Name,
  ty : @knf.Type,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self
    .expr_codegen(expr)
    .or_error(CodegenError("unable to gen code of \{expr}"))
  self.name_values.set(name, value)
  self.name_types.set(name, ty)
}

///|
pub fn Context::let_mut_stmt_codegen(
  self : Self,
  name : @knf.Name,
  ty : @knf.Type,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self
    .expr_codegen(expr)
    .or_error(CodegenError("unable to gen code of \{expr}"))

  // allocate space for the mutable variable on the stack
  let ptr = self.builder.createAlloca(self.type_codegen_opaque(ty))

  // store the initial value into the allocated slot
  self.builder.createStore(value, ptr) |> ignore

  // map the variable name to the pointer so future accesses know it's an alloca
  self.name_values.set(name, ptr)
  self.name_types.set(name, ty)
}

///|
pub fn Context::assign_stmt_codegen(
  self : Self,
  name : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self
    .expr_codegen(expr)
    .or_error(CodegenError("unable to gen code of \{expr}"))
  let ptr = self.name_values
    .get(name)
    .or_error(CodegenError("unable to find variable \{name} for assignment"))
  self.builder.createStore(value, ptr) |> ignore
}

///|
pub fn Context::array_put_codegen(
  self : Self,
  name : @knf.Name,
  idx : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self
    .expr_codegen(expr)
    .or_error(CodegenError("unable to gen code of \{expr}"))
  let ptr = self.name_values
    .get(name)
    .or_error(
      CodegenError("unable to find array variable \{name} for ArrayPut"),
    )
  let idx_value = self.name_values
    .get(idx)
    .or_error(CodegenError("unable to find index variable \{idx} for ArrayPut"))
  let array_ty = self.name_types
    .get(name)
    .or_error(
      CodegenError("unable to find type of array variable \{name} for ArrayPut"),
    )
  let elem_ty = match array_ty {
    Array(elem_ty) => elem_ty
    _ => raise CodegenError("\{name} is not an array type for ArrayPut")
  }
  // determine the builtin function name
  let put_func_name = match elem_ty {
    Int => "array_int_put"
    Double => "array_double_put"
    Bool => "array_bool_put"
    String => "array_string_put"
    _ =>
      raise CodegenError("Array::put not supported for element type \{elem_ty}")
  }
  // get the builtin function
  let put_func = self.builtin_funcs
    .get(put_func_name)
    .or_error(CodegenError("unable to find builtin function \{put_func_name}"))
  // create call instruction
  self.builder.createCall(put_func, [ptr, idx_value, value]) |> ignore
}

///|
pub fn Context::struct_field_set_codegen(
  self : Self,
  name : @knf.Name,
  field : String,
  value_name : @knf.Name,
) -> Unit raise {
  ignore(self)
  ignore(name)
  ignore(field)
  ignore(value_name)
  raise CodegenError("StructFieldSet codegen not implemented yet")
}
