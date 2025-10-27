///|
pub(all) struct Param {
  name : String
  ty : TypeKind
} derive(Show)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : TypeKind
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_top_function(
  self : Context,
  func : @parser.TopFunction,
) -> TopFunction raise TypeCheckError {
  let fname = func.fname
  let ty_def = self.func_types
    .get(fname)
    .or_error(
      TypeCheckError(
        "[Context::check_top_function] unable to find type of \{fname}",
      ),
    )
  // let (param_tys, ret_ty) = match ty_def {
  //   Function(pts, rt) => (pts, rt)
  //   _ =>
  //     raise TypeCheckError(
  //       "[Context::check_top_function] \{fname}'s type must be Function",
  //     )
  // }
  // typecheck
  let ret_ty = self.check_parser_typekind(func.ret_ty.kind)
  let param_list = func.param_list.map(fn(p) {
    Param::{ name: p.name, ty: self.check_parser_typekind(p.ty.kind) }
  })
  let param_tys = param_list.map(fn(p) { p.ty })
  let func_type = TypeKind::Function(param_tys, ret_ty)
  if !self.is_type_compatible(ty_def, func_type) {
    raise TypeCheckError(
      "[Context::check_top_function] def[\{func_type}] and sig[\{ty_def}] mismatch",
    )
  }
  // procesws scope
  self.enter_scope()
  self.current_func_ret_ty = Some(ret_ty)
  for param in func.param_list {
    let panem = param.name
    let pty = self.check_parser_type(param.ty)
    self.type_env.set(panem, pty)
  }
  let body = self.check_block_expr(func.body)
  if !self.is_type_compatible(ret_ty, body.ty) {
    let ty_info = "expected: \{ret_ty}, actual: \{body.ty}"
    raise TypeCheckError(
      "[Context::check_top_function] ret type mismatch, \{ty_info}",
    )
  }
  self.current_func_ret_ty = None
  self.exit_scope()
  // finish process scope
  TopFunction::{ fname, param_list, ret_ty, body }
}
