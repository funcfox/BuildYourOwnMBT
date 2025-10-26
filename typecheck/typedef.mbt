///|
pub(all) struct Type {
  kind : TypeKind
  mutable : Bool
} derive(Show)

///|
pub(all) enum TypeKind {
  Unit
  Bool
  Int
  Double
  String
  Tuple(Array[TypeKind])
  Array(TypeKind)
  Function(Array[TypeKind], TypeKind)
  Struct(String)
  Any
  TypeVar(Int)
} derive(Hash)

///|
pub fn Context::check_parser_typekind(
  self : Context,
  ty : @parser.TypeKind,
) -> TypeKind raise TypeCheckError {
  match ty {
    Unit => Unit
    Bool => Bool
    Int => Int
    Double => Double
    String => String
    Tuple(arr) => Tuple(arr.map(fn(t) { self.check_parser_typekind(t) }))
    Array(t) => Array(self.check_parser_typekind(t))
    Function(param_tys, ret_ty) =>
      Function(
        param_tys.map(fn(t) { self.check_parser_typekind(t) }),
        self.check_parser_typekind(ret_ty),
      )
    Defined(name) =>
      if self.struct_defs.contains(name) {
        Struct(name)
      } else {
        raise TypeCheckError("struct \{name} undefined")
      }
  }
}

///|
pub fn Context::check_parser_type(
  self : Context,
  ty : @parser.Type,
  mutable? : Bool = false,
) -> Type raise TypeCheckError {
  match ty {
    { kind: tk } => Type::{ kind: self.check_parser_typekind(tk), mutable }
  }
}

///|
pub fn Context::is_type_compatible(
  self : Context,
  a : TypeKind,
  b : TypeKind,
) -> Bool raise TypeCheckError {
  // println("a: \{a}, b: \{b}, type_vars: \{self.type_vars}")
  match (a, b) {
    (Unit, Unit) => true
    (Bool, Bool) => true
    (Int, Int) => true
    (Double, Double) => true
    (String, String) => true
    (Tuple(tkaa), Tuple(tkab)) => self.is_type_arr_compatible(tkaa, tkab)
    (Array(ka), Array(kb)) => self.is_type_compatible(ka, kb)
    (Function(ata, rta), Function(atb, rtb)) =>
      self.is_type_compatible(rta, rtb) && self.is_type_arr_compatible(ata, atb)
    (Struct(snamea), Struct(snameb)) => snamea == snameb
    (Any, Any) => true // TODO: check rule about Any
    (TypeVar(tvida), TypeVar(tvidb)) => {
      let tya = self.query_typevar(tvida)
      let tyb = self.query_typevar(tvidb)
      // self.is_type_compatible(tya, tyb)
      match (tya, tyb) {
        (TypeVar(ida), TypeVar(_) as tt) =>
          self.set_var_type_to_typekind(ida, tt)
        _ => self.is_type_compatible(tya, tyb)
      }
    }
    (TypeVar(tvida), tb) => self.set_var_type_to_typekind(tvida, tb)
    (ta, TypeVar(tvidb)) => self.set_var_type_to_typekind(tvidb, ta)
    // _ => raise TypeCheckError("is_type_compatible(\{a}, \{b}) not impl yet")
    _ => false
  }
}

///|
fn Context::is_type_arr_compatible(
  self : Context,
  tkaa : Array[TypeKind],
  tkab : Array[TypeKind],
) -> Bool raise TypeCheckError {
  loop (tkaa[:], tkab[:]) {
    ([_, ..], []) => break false
    ([], [_, ..]) => break false
    ([], []) => break true
    ([ta, .. resta], [tb, .. restb]) =>
      if self.is_type_compatible(ta, tb) {
        continue (resta, restb)
      } else {
        break false
      }
  }
}

///|
fn Context::set_var_type_to_typekind(
  self : Self,
  tkid_set : Int,
  tk_to : TypeKind,
) -> Bool raise TypeCheckError {
  let qty_set = self.query_typevar(tkid_set)
  let qty_to = match tk_to {
    TypeVar(tvid) => self.query_typevar(tvid)
    t => t
  }
  match qty_set {
    TypeVar(tvids) => {
      self.type_vars.set(tvids, qty_to)
      self.update_type_vars()
      true
    }
    _ => self.is_type_compatible(qty_set, qty_to)
  }
}

///|
fn Context::query_typevar(
  self : Self,
  tvid : Int,
) -> TypeKind raise TypeCheckError {
  let result = self.type_vars
    .get(tvid)
    .or_error(TypeCheckError("invalid TypeVar id: \{tvid}"))
  match result {
    TypeVar(tvr) =>
      if tvid == tvr {
        result
      } else {
        let qty = self.query_typevar(tvr)
        self.type_vars.set(tvid, qty)
        qty
      }
    ty => {
      self.type_vars.set(tvid, ty)
      ty
    }
  }
}

///|
fn Context::get_typekind(
  self : Self,
  kind : TypeKind,
) -> TypeKind raise TypeCheckError {
  match kind {
    TypeVar(tvid) => self.query_typevar(tvid)
    Array(TypeVar(tvid)) => Array(self.query_typevar(tvid))
    Tuple(kind_arr) => Tuple(kind_arr.map(fn(k) { self.get_typekind(k) }))
    Function(arg_kinds, ret_kind) =>
      Function(
        arg_kinds.map(fn(k) { self.get_typekind(k) }),
        self.get_typekind(ret_kind),
      )
    _ => kind
  }
}

///|
fn Context::update_type_vars(self : Self) -> Unit raise TypeCheckError {
  for it in self.type_vars.iter() {
    if it.1 is TypeVar(_) {
      let qt = match it.1 {
        TypeVar(tid) => self.query_typevar(tid)
        _ => raise TypeCheckError("update_type_vars: it must be a TypeVar")
      }
      self.type_vars.set(it.0, qt)
    }
  }
}

///|
pub impl Show for TypeKind with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Bool => "Bool"
    Int => "Int"
    Double => "Double"
    String => "String"
    Tuple(types) => {
      let inner = types.map(typekind => typekind.to_string()).join(", ")
      "(\{inner})"
    }
    Array(elem_type) => "Array[\{elem_type.to_string()}]"
    Function(param_types, return_type) => {
      let params = param_types.map(typekind => typekind.to_string()).join(", ")
      "(\{params}) -> \{return_type.to_string()}"
    }
    Struct(name) => "\{name}"
    Any => "Any"
    TypeVar(name) => "TypeVar(\{name})"
  }
  logger.write_string(s)
}
