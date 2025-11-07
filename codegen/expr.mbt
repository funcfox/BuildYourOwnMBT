///|
///
/// 注意这里的expr_codegen的返回值是Option[&@llvm.Value]
/// 对于Unit类型的表达式，应当返回None做特殊处理。
///
/// 对于像let a: Unit = (); 这种表达式，可以考虑把a的值设为null指针，
/// 使用llvm_ctx.getConstPointerNull(llvm_ctx.getPtrTy())
pub fn Context::expr_codegen(
  self : Self,
  expr : @knf.KnfExpr,
) -> &@llvm.Value? raise {
  fn wmsg(msg : String) -> String {
    "[Context::expr_codegen]: \{msg}"
  }

  match expr {
    Int(i) => (self.llvm_ctx.getConstInt32(i) : &@llvm.Value) |> Some
    Double(d) => (self.llvm_ctx.getConstDouble(d) as &@llvm.Value) |> Some
    Bool(b) => (self.llvm_ctx.getConstBool(b) as &@llvm.Value) |> Some
    String(s) =>
      {
        let ret_value = self.builder.createGlobalString(
            s,
            name="str_lit_\{self.str_cnt}",
          )
          as &@llvm.Value
        self.str_cnt += 1
        ret_value
      }
      |> Some
    Ident(name) =>
      {
        let value = self.name_values
          .get(name)
          .or_error(CodegenError("unable to find value of \{name}"))
        let ty = self.name_types
          .get(name)
          .or_error(CodegenError("unable to find type of \{name}"))
        let ty_llvm = self.type_codegen_opaque(ty)
        if value.asValueEnum() is AllocaInst(_) {
          self.builder.createLoad(ty_llvm, value)
        } else {
          value
        }
      }
      |> Some
    Binary(op, left, right) =>
      {
        let val_left = self.name_values
          .get(left)
          .or_error(CodegenError("unable to find binop left value \{left}"))
        let val_right = self.name_values
          .get(right)
          .or_error(CodegenError("unable to find binop right value \{left}"))
        let is_float = val_left.getType().isIEEELikeFPTy()
        match op {
          // ShiftLeft // <<
          // ShiftRight // >>
          // And // &&
          // Or // ||
          // BitAnd // &
          // BitOr // |
          Add =>
            if is_float {
              self.builder.createFAdd(val_left, val_right)
            } else {
              self.builder.createAdd(val_left, val_right)
            }
          Sub =>
            if is_float {
              self.builder.createFSub(val_left, val_right)
            } else {
              self.builder.createSub(val_left, val_right)
            }
          Mul =>
            if is_float {
              self.builder.createFMul(val_left, val_right)
            } else {
              self.builder.createMul(val_left, val_right)
            }
          Div =>
            if is_float {
              self.builder.createFDiv(val_left, val_right)
            } else {
              self.builder.createSDiv(val_left, val_right)
            }
          Mod =>
            if is_float {
              self.builder.createFRem(val_left, val_right) // should not be call
            } else {
              self.builder.createSRem(val_left, val_right)
            }
          Eq =>
            if is_float {
              self.builder.createFCmpOEQ(val_left, val_right)
            } else {
              self.builder.createICmpEQ(val_left, val_right)
            }
          NE =>
            if is_float {
              self.builder.createFCmpONE(val_left, val_right)
            } else {
              self.builder.createICmpNE(val_left, val_right)
            }
          GT =>
            if is_float {
              self.builder.createFCmpOGT(val_left, val_right)
            } else {
              self.builder.createICmpSGT(val_left, val_right)
            }
          GE =>
            if is_float {
              self.builder.createFCmpOGE(val_left, val_right)
            } else {
              self.builder.createICmpSGE(val_left, val_right)
            }
          LT =>
            if is_float {
              self.builder.createFCmpOLT(val_left, val_right)
            } else {
              self.builder.createICmpSLT(val_left, val_right)
            }
          LE =>
            if is_float {
              self.builder.createFCmpOLE(val_left, val_right)
            } else {
              self.builder.createICmpSLE(val_left, val_right)
            }
          _ => raise CodegenError("binop '\{op}' not impl yet")
        }
      }
      |> Some
    Neg(expr) =>
      {
        let value = self.name_values
          .get(expr)
          .or_error(CodegenError("unable to find neg expr value \{expr}"))
        if value.getType().isIEEELikeFPTy() {
          self.builder.createFNeg(value)
        } else {
          let zero = self.llvm_ctx.getConstInt32(0) as &@llvm.Value
          self.builder.createSub(zero, value)
        }
      }
      |> Some
    Not(expr) =>
      {
        let value = self.name_values
          .get(expr)
          .or_error(CodegenError("unable to find not expr value \{expr}"))
        let true_val = self.llvm_ctx.getConstTrue() as &@llvm.Value
        self.builder.createXor(true_val, value)
      }
      |> Some
    ArrayMake(size_name, init_name) =>
      {
        // get the type of init_name
        let init_ty = self.name_types
          .get(init_name)
          .or_error(CodegenError("unable to find type of \{init_name}"))
        // determine the builtin function name
        let make_func_name = match init_ty {
          Int => "make_int_array"
          Double => "make_double_array"
          Bool => "make_bool_array"
          String => "make_string_array"
          _ =>
            raise CodegenError(
              "Array::make not supported for element type \{init_ty}",
            )
        }
        // get the builtin function
        let make_array_func = self.builtin_funcs
          .get(make_func_name)
          .or_error(
            CodegenError("unable to find builtin function \{make_func_name}"),
          )
        // get size and init values
        let size_value = self.name_values
          .get(size_name)
          .or_error(CodegenError("unable to find size value \{size_name}"))
        let init_value = self.name_values
          .get(init_name)
          .or_error(CodegenError("unable to find init value \{init_name}"))
        // create call instruction
        self.builder.createCall(make_array_func, [size_value, init_value])
      }
      |> Some
    ArrayAccess(array_name, index_name) =>
      {
        let arr_ty = self.name_types
          .get(array_name)
          .or_error(CodegenError("unable to find type of \{array_name}"))
        let elem_ty = match arr_ty {
          @knf.Type::Array(inner_ty) => inner_ty
          _ => raise CodegenError("\{array_name} is not an array type")
        }
        let index_value = self.name_values
          .get(index_name)
          .or_error(CodegenError("unable to find index value \{index_name}"))
        let array_value = self.name_values
          .get(array_name)
          .or_error(CodegenError("unable to find array value \{array_name}"))
        // determine the builtin function name
        let get_func_name = match elem_ty {
          Int => "array_int_get"
          Double => "array_double_get"
          Bool => "array_bool_get"
          String => "array_string_get"
          _ =>
            raise CodegenError(
              "Array::get not supported for element type \{elem_ty}",
            )
        }
        // get the builtin function
        let get_array_func = self.builtin_funcs
          .get(get_func_name)
          .or_error(
            CodegenError("unable to find builtin function \{get_func_name}"),
          )
        // create call instruction
        self.builder.createCall(get_array_func, [array_value, index_value])
      }
      |> Some
    ArrayLiteral(ty, values) => {
      let elem_ty = match ty {
        @knf.Type::Array(inner_ty) => inner_ty
        _ => raise CodegenError("ArrayLiteral type \{ty} is not an array type")
      }
      // determine the builtin function names
      let make_func_name = match elem_ty {
        Int => "make_int_array"
        Double => "make_double_array"
        Bool => "make_bool_array"
        String => "make_string_array"
        _ =>
          raise CodegenError(
            "Array::make not supported for element type \{elem_ty}",
          )
      }
      // create call instruction to make the array
      let make_array_func = self.builtin_funcs
        .get(make_func_name)
        .or_error(
          CodegenError("unable to find builtin function \{make_func_name}"),
        )
      let size_value = self.llvm_ctx.getConstInt32(values.length())
        as &@llvm.Value
      // for init value, we can use any default value of the element type
      let init_value = match elem_ty {
        Int => self.llvm_ctx.getConstInt32(0) as &@llvm.Value
        Double => self.llvm_ctx.getConstDouble(0.0) as &@llvm.Value
        Bool => self.llvm_ctx.getConstBool(false) as &@llvm.Value
        String => {
          let ret_value = self.builder.createGlobalString(
              "",
              name="str_lit_\{self.str_cnt}",
            )
            as &@llvm.Value
          self.str_cnt += 1
          ret_value
        } // TODO: check impl
        _ => raise CodegenError("Unsupported element type in array literal")
      }
      let array_ptr = self.builder.createCall(make_array_func, [
        size_value, init_value,
      ])
      // determine the builtin function name for put
      let put_func_name = match elem_ty {
        Int => "array_int_put"
        Double => "array_double_put"
        Bool => "array_bool_put"
        String => "array_string_put"
        _ =>
          raise CodegenError(
            "Array::put not supported for element type \{elem_ty}",
          )
      }
      // get the builtin function
      let put_array_func = self.builtin_funcs
        .get(put_func_name)
        .or_error(
          CodegenError("unable to find builtin function \{put_func_name}"),
        )
      // fill in the elements
      for i, val_name in values.iter2() {
        let val_value = self.name_values
          .get(val_name)
          .or_error(
            CodegenError(
              "unable to find array literal element value \{val_name}",
            ),
          )
        let index_value = self.llvm_ctx.getConstInt32(i) as &@llvm.Value
        // create call instruction to put the element
        self.builder.createCall(put_array_func, [
          array_ptr, index_value, val_value,
        ])
        |> ignore
      }
      array_ptr |> Some
    }
    Block(block) => self.block_codegen(block)
    If(cond, then_block, else_block) =>
      self.if_codegen(cond, then_block, else_block)
    CreateStruct(name, fields) => {
      let ty = self.struct_types
        .get(name)
        .or_error(CodegenError(wmsg("unable to find struct type: \{name}")))
      // malloc struct space
      let malloc_func = self.builtin_funcs
        .get("moonbit_malloc")
        .or_error(CodegenError(""))
      let struct_size = self.llvm_mod.getDataLayout().getTypeAllocSize(ty)
      let struct_ptr = self.builder.createCall(malloc_func, [
        self.llvm_ctx.getConstInt32(struct_size),
      ])
      // fill in fields
      let knf_struct_def = self.knf_struct_types
        .get(name)
        .or_error(CodegenError(wmsg("unable to find knf struct def: \{name}")))
      for it in fields.iter() {
        let (field_name, field_value_name) = it
        let field_idx = knf_struct_def.fields
          .search_by(fn(k) { k.0 == field_name })
          .or_error(
            CodegenError(
              wmsg("unable to find field \{field_name} in struct \{name}"),
            ),
          )
        let field_ptr = self.builder.createGEP(struct_ptr, ty, [
          self.llvm_ctx.getConstInt32(0),
          self.llvm_ctx.getConstInt32(field_idx),
        ])
        let field_value = self.name_values
          .get(field_value_name)
          .or_error(
            CodegenError(wmsg("unable to find value for field \{field_name}")),
          )
        self.builder.createStore(field_value, field_ptr) |> ignore
      }
      struct_ptr |> Some
    }
    FieldAccess(struct_name, field_name) => {
      let ty = self.name_types
        .get(struct_name)
        .or_error(CodegenError(wmsg("unable to find type of \{struct_name}")))
      let struct_name_str = match ty {
        Struct(sname) => sname
        _ => raise CodegenError(wmsg("\{struct_name} is not a struct type"))
      }
      let struct_def = self.knf_struct_types
        .get(struct_name_str)
        .or_error(
          CodegenError(
            wmsg("unable to find knf struct def: \{struct_name_str}"),
          ),
        )
      let struct_ty = self.struct_types
        .get(struct_name_str)
        .or_error(
          CodegenError(wmsg("unable to find struct type: \{struct_name_str}")),
        )
      let field_idx = struct_def.fields
        .search_by(fn(k) { k.0 == field_name })
        .or_error(
          CodegenError(
            wmsg("unable to find field \{field_name} in struct \{struct_name}"),
          ),
        )
      let struct_value = self.name_values
        .get(struct_name)
        .or_error(CodegenError(wmsg("unable to find value of \{struct_name}")))
      let field_ptr = self.builder.createGEP(struct_value, struct_ty, [
        self.llvm_ctx.getConstInt32(0),
        self.llvm_ctx.getConstInt32(field_idx),
      ])
      let field_ty = self.type_codegen_opaque(struct_def.fields[field_idx].2)
      self.builder.createLoad(field_ty, field_ptr) |> Some
    }
    TupleAccess(name, idx) => {
      let ty = self.name_types
        .get(name)
        .or_error(CodegenError(wmsg("unable to find type of \{name}")))
      let anon_struct_ty = match ty {
        Tuple(elem_tys) => self.tuple_ty_to_anon_struct_ty(elem_tys)
        _ => raise CodegenError(wmsg("\{name} is not a tuple type"))
      }
      let tuple_value = self.name_values
        .get(name)
        .or_error(CodegenError(wmsg("unable to find value of \{name}")))
      let elem_ptr = self.builder.createGEP(tuple_value, anon_struct_ty, [
        self.llvm_ctx.getConstInt32(0),
        self.llvm_ctx.getConstInt32(idx),
      ])
      let elem_ty = match ty {
        Tuple(elem_tys) => self.type_codegen_opaque(elem_tys[idx])
        _ => raise CodegenError("unreachable")
      }
      self.builder.createLoad(elem_ty, elem_ptr) |> Some
    }
    e => raise CodegenError("Unsupported expression in codegen: \{e}")
  }
}

///|
fn Context::tuple_ty_to_anon_struct_ty(
  self : Self,
  tys : Array[@knf.Type],
) -> @llvm.StructType raise {
  let llvm_tys = tys.map(fn(t) { self.type_codegen_opaque(t) })
  self.llvm_ctx.getStructType(llvm_tys)
}
