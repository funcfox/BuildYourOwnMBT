///|
pub(all) struct LocalFunction {
  fname : String
  param_list : Array[(String, Type)]
  ret_ty : Type
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_local_function(
  self : Context,
  func : @parser.LocalFunction,
) -> LocalFunction raise TypeCheckError {
  let fname = func.fname
  let param_list = func.param_list.map(fn(p) {
    match p {
      (pname, Some(pt)) => (pname, self.check_parser_type(pt))
      (pname, None) =>
        (pname, Type::{ kind: self.new_typevar(), mutable: false })
    }
  })
  let ret_ty = match func.ret_ty {
    Some(rty) => self.check_parser_type(rty)
    None => Type::{ kind: self.new_typevar(), mutable: false }
  }
  let func_type = Function(param_list.map(fn(p) { p.1.kind }), ret_ty.kind)
  // self.func_types.set(fname, func_type)
  self.type_env.set(fname, Type::{ kind: func_type, mutable: false })
  // process scope
  self.enter_scope()
  self.current_func_ret_ty = Some(ret_ty.kind)
  for pm in param_list {
    self.type_env.set(pm.0, pm.1)
  }
  let body = self.check_block_expr(func.body)
  if !self.is_type_compatible(body.ty, ret_ty.kind) {
    raise TypeCheckError(
      "[Context::check_local_function] rettype sig[\{ret_ty.kind}], body[\{body.ty}] mismatch",
    )
  }
  self.current_func_ret_ty = None // TODO: check here
  self.exit_scope()
  // finish scope
  let ret_ty = Type::{
    kind: self.get_typekind(ret_ty.kind),
    mutable: ret_ty.mutable,
  }
  let param_list = param_list.map(fn(pm) {
    match pm {
      (name, { kind, mutable }) =>
        (name, Type::{ kind: self.get_typekind(kind), mutable })
    }
  })
  LocalFunction::{ fname, param_list, ret_ty, body }
}
