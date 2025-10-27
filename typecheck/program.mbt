///|
typealias @either.Either

///|
pub(all) suberror TypeCheckError String derive(Show)

///|
pub(all) struct Env {
  local_ : Map[String, Type]
  parent : Env?
}

///|
pub fn Env::new(parent? : Env? = None) -> Env {
  Env::{ local_: Map::new(), parent }
}

///|
pub fn Env::get(self : Env, name : String) -> Type? {
  match self.local_.get(name) {
    Some(t) => Some(t)
    None =>
      match self.parent {
        Some(p) => p.get(name)
        None => None
      }
  }
}

///|
pub fn Env::set(self : Env, name : String, t : Type) -> Unit {
  self.local_.set(name, t)
}

///|
pub(all) struct Context {
  mut type_env : Env
  type_vars : Map[Int, TypeKind]
  struct_defs : Map[String, StructDef]
  func_types : Map[String, TypeKind]
  mut current_func_ret_ty : TypeKind?
}

///|
pub fn Context::new() -> Context {
  Context::{
    type_env: Env::new(),
    type_vars: Map::new(),
    struct_defs: Map::new(),
    func_types: Map::new(),
    current_func_ret_ty: None,
  }
}

///|
pub fn Context::lookup_type(self : Context, name : String) -> Type? {
  // ignore(self)
  // ignore(name)
  // None
  match self.type_env.get(name) {
    Some({ kind, mutable }) => {
      let kind = self.get_typekind(kind) catch { _ => return None }
      let ty = Type::{ kind, mutable }
      Some(ty)
    }
    None => None
  }
}

///|
pub fn Context::enter_scope(self : Self) -> Unit {
  let sub_env = Env::new(parent=Some(self.type_env))
  self.type_env = sub_env
}

///|
pub fn Context::exit_scope(self : Context) -> Unit {
  self.type_env = match self.type_env.parent {
    Some(p) => p
    None => self.type_env
  }
}

///|
pub fn Context::set_current_func_ret_ty(self : Context, ty : TypeKind) -> Unit {
  self.current_func_ret_ty = Some(ty)
}

///|
fn Context::new_typevar(self : Self) -> TypeKind {
  let new_id = self.type_vars.length()
  let ty = TypeKind::TypeVar(new_id)
  self.type_vars.set(new_id, ty) // TODO: check here
  ty
}

///|
pub(all) struct Program {
  top_lets : Map[String, TopLet]
  top_functions : Map[String, TopFunction]
  struct_defs : Map[String, StructDef]
} derive(Show)

///|
pub fn Context::check_program(
  self : Context,
  program : @parser.Program,
) -> Program raise TypeCheckError {
  self.collect_struct_names(program)
  // raise TypeCheckError("[Context::check_program] debug halt")
  self.collect_function_types(program)
  let top_lets = Map::new()
  program.top_lets.each(fn(name, tl) {
    let tl = self.check_top_let(tl)
    top_lets.set(name, tl)
  })
  let top_functions = Map::new()
  program.top_functions.each(fn(name, tf) {
    let tf = self.check_top_function(tf)
    top_functions.set(name, tf)
  })
  let struct_defs = Map::new()
  program.struct_defs.each(fn(name, sd) {
    let sd = self.check_struct_def(sd)
    struct_defs.set(name, sd)
  })
  Program::{ top_lets, top_functions, struct_defs }
}

///|
pub fn Context::collect_struct_names(
  self : Context,
  program : @parser.Program,
) -> Unit {
  program.struct_defs.each(fn(name, sdef) {
    self.struct_defs.set(name, StructDef::{ name: sdef.name, fields: [] })
  })
}

///|
pub fn Context::collect_function_types(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  program.top_functions.each(fn(fname, fdef) {
    let kind = {
      let param_tys = fdef.param_list.map(fn(p) {
        self.check_parser_typekind(p.ty.kind)
      })
      let ret_ty = self.check_parser_typekind(fdef.ret_ty.kind)
      TypeKind::Function(param_tys, ret_ty)
    }
    let ty = Type::{ kind, mutable: false }
    self.type_env.set(fname, ty)
    self.func_types.set(fname, kind)
  })
}
