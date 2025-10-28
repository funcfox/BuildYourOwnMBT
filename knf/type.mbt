///|
pub(all) enum Type {
  Unit
  Int
  Bool
  Double
  String
  Array(Type)
  Struct(String)
  Tuple(Array[Type])
  Function(Array[Type], Type)
}

///|
pub impl Show for Type with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Int => "Int"
    Bool => "Bool"
    Double => "Double"
    String => "String"
    Array(elem_type) => "Array[\{elem_type}]"
    Struct(name) => "\{name}"
    Tuple(elem_types) => {
      let elem_strs = elem_types.map(et => "\{et}").join(", ")
      "(\{elem_strs})"
    }
    Function(param_types, ret_type) => {
      let param_strs = param_types.map(pt => "\{pt}").join(", ")
      "(\{param_strs}) -> \{ret_type}"
    }
  }
  logger.write_string(s)
}

///|
pub fn Context::typekind_to_knf(
  self : Context,
  tk : @typecheck.TypeKind,
) -> Type raise KnfTransformError {
  match tk {
    Struct(n) => Struct(n)
    Function(arg_tks, ret_tk) =>
      Function(
        arg_tks.map(fn(k) { self.typekind_to_knf(k) }),
        self.typekind_to_knf(ret_tk),
      )
    Array(k) => Array(self.typekind_to_knf(k))
    Tuple(tk_arr) => Tuple(tk_arr.map(fn(k) { self.typekind_to_knf(k) }))
    String => String
    Double => Double
    Int => Int
    Bool => Bool
    Unit => Unit
    _ =>
      raise KnfTransformError(
        "[Context::typekind_to_knf] unsatisfied type \{tk}",
      )
  }
}

///|
pub fn Context::type_to_knf(
  self : Context,
  t : @typecheck.Type,
) -> Type raise KnfTransformError {
  self.typekind_to_knf(t.kind)
}
