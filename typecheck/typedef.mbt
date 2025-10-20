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
  ignore(self)
  ignore(ty)
  raise TypeCheckError("check_parser_typekind not implemented")
}

///|
pub fn Context::check_parser_type(
  self : Context,
  ty : @parser.Type,
  mutable? : Bool = false,
) -> Type raise TypeCheckError {
  ignore(self)
  ignore(ty)
  ignore(mutable)
  raise TypeCheckError("check_parser_type not implemented")
}

///|
pub fn Context::is_type_compatible(
  self : Context,
  a : TypeKind,
  b : TypeKind,
) -> Bool raise TypeCheckError {
  ignore(self)
  ignore(a)
  ignore(b)
  raise TypeCheckError("is_type_compatible not implemented")
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
