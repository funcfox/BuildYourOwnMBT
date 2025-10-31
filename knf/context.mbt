///|
pub(all) suberror KnfTransformError String derive(Show)

///|
pub typealias @either.Either

///|
pub(all) struct Name {
  id : String
  slot : Int
} derive(Hash, Eq)

///|
pub fn Name::wildcard() -> Name {
  Name::{ id: "_", slot: 0 }
}

///|
pub impl Show for Name with output(self, logger) {
  logger.write_string(self.id)
  if self.slot > 0 {
    logger.write_string("$\{self.slot}")
  }
}

///|
pub(all) struct Env {
  local_ : Map[String, (Name, Type)] // defined in this scope
  capture : Map[Name, Type] // captured from outer scopes
  parent : Env?
}

///|
pub fn Env::new(parent? : Env? = None) -> Env {
  Env::{ local_: Map::new(), capture: Map::new(), parent }
}

///|
pub fn Env::get_name_type(self : Env, name : Name) -> Type? {
  let { id, .. } = name
  match self.local_.get(id) {
    Some((_, t)) => Some(t)
    None =>
      match self.parent {
        Some(p) => p.get_name_type(name)
        None => None
      }
  }
}

///|
pub fn Env::get(self : Env, name : String) -> Name? {
  match self.local_.get(name) {
    Some((n, _)) => Some(n)
    None =>
      match self.parent {
        Some(p) => p.get(name)
        None => None
      }
  }
}

///|
pub fn Env::set(self : Env, s : String, name : Name, ty : Type) -> Unit {
  self.local_.set(s, (name, ty))
}

///|
pub(all) struct Context {
  mut name_env : Env
  capture : Array[Name]
  globals : Map[String, Type]
}

///|
pub fn Context::new() -> Context {
  Context::{ name_env: Env::new(), capture: Array::new(), globals: Map::new() }
}

///|
pub fn Context::lookup_name(self : Context, s : String) -> (Name, Type)? {
  let name_ = loop (self.name_env.get(s), self.name_env.parent) {
    (Some(name), _) => break Some(name)
    (None, Some(parent)) => continue (parent.get(s), parent.parent)
    (None, None) => break None
  }
  if name_ is Some(name) {
    self.name_env.get_name_type(name).map(fn(ty) { (name, ty) })
  } else {
    self.globals
    .get(s)
    .map(fn(ty) {
      let name = Name::{ id: s, slot: 0 } // TODO: check impl
      (name, ty)
    })
  }
}

///|
pub fn Context::enter_scope(self : Context) -> Unit {
  let sub_env = Env::new(parent=Some(self.name_env))
  self.name_env = sub_env
}

///|
pub fn Context::exit_scope(self : Context) -> Unit {
  self.name_env = match self.name_env.parent {
    Some(p) => p
    None => self.name_env
  }
}

///|
pub fn Context::add_new_name(self : Context, s : String, ty : Type) -> Name {
  match self.name_env.get(s) {
    Some({ id, slot }) => {
      let name = Name::{ id, slot: slot + 1 }
      self.name_env.set(s, name, ty)
      name
    }
    None => {
      let name = Name::{ id: s, slot: 0 }
      self.name_env.set(s, name, ty)
      name
    }
  }
}

///|
pub fn Context::add_temp(self : Context, ty : Type) -> Name {
  let temp_id = "tmp"
  self.add_new_name(temp_id, ty)
}
