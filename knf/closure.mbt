///|
pub(all) struct KnfClosure {
  name : Name
  params : Array[(Name, Type)]
  ret_ty : Type
  body : KnfBlock
  captured_vars : Map[Name, Type]
}

///|
pub fn KnfClosure::to_string(self : KnfClosure, ident? : Int = 0) -> String {
  let sb = StringBuilder::new()
  let indent_str = " ".repeat(ident)
  if !self.captured_vars.is_empty() {
    sb.write_string("// Captured variables: \n")
    for name, ty in self.captured_vars {
      sb.write_string(indent_str)
      sb.write_string("// - \{name} : \{ty}\n")
    }
    sb.write_string(indent_str)
    sb.write_string("fn \{self.name}(")
  } else {
    sb.write_string("fn \{self.name}(")
  }
  let param_strs = self.params.map(name_ty => {
    let (name, ty) = name_ty
    "\{name} : \{ty}"
  })
  sb.write_string(param_strs.join(", "))
  sb.write_string(") -> \{self.ret_ty} ")
  sb.write_string(self.body.to_string(ident))
  sb.to_string()
}

///|
pub fn Context::local_function_to_knf(
  self : Context,
  local_function : @typecheck.LocalFunction,
) -> KnfClosure raise KnfTransformError {
  ignore(self)
  ignore(local_function)
  raise KnfTransformError("LocalFunction Knf transformation not implemented")
}
