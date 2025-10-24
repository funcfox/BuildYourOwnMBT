///|
pub(all) struct Type {
  kind : TypeKind
} derive(Show, Eq)

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
  Defined(String)
} derive(Hash, Eq) // Show defined manually in `parser_aux.mbt`

///|
pub fn parse_type(
  tokens : ArrayView[Token],
) -> (Type, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Upper("Unit") }, .. rest] => (Type::{ kind: TypeKind::Unit }, rest)
    [{ kind: Upper("Bool") }, .. rest] => (Type::{ kind: TypeKind::Bool }, rest)
    [{ kind: Upper("Int") }, .. rest] => (Type::{ kind: TypeKind::Int }, rest)
    [{ kind: Upper("Double") }, .. rest] =>
      (Type::{ kind: TypeKind::Double }, rest)
    [{ kind: Upper("String") }, .. rest] =>
      (Type::{ kind: TypeKind::String }, rest)
    [{ kind: Upper("Array") }, { kind: Bracket('[') }, .. rest] => {
      let (ty, rest) = parse_type(rest)
      let rest = match rest {
        [{ kind: Bracket(']') }, .. rst] => rst
        _ => raise ParseError("expected ']'")
      }
      (Type::{ kind: TypeKind::Array(ty.kind) }, rest)
    }
    [{ kind: Bracket('(') }, .. rest] => {
      let mut rest = rest
      let inner = []
      while !(rest is [{ kind: Bracket(')') }, ..]) {
        let (ty, rest_) = parse_type(rest)
        rest = rest_
        inner.push(ty.kind)
        rest = match rest {
          [{ kind: Symbol(",") }, .. rst] => rst
          _ => rest
        }
      }
      rest = match rest {
        [{ kind: Bracket(')') }, .. rst] => rst
        _ => raise ParseError("expected a ')'")
      }
      match rest {
        [{ kind: Symbol("->") }, .. rst] => {
          let (ty, rst) = parse_type(rst)
          (Type::{ kind: TypeKind::Function(inner, ty.kind) }, rst)
        }
        _ => (Type::{ kind: TypeKind::Tuple(inner) }, rest)
      }
    }
    [{ kind: Upper(type_name) }, .. rest] =>
      (Type::{ kind: TypeKind::Defined(type_name) }, rest)
    _ => raise ParseError("unknown type: \{tokens[0]}")
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
    Tuple(tys) => {
      let inner = tys.map(ty => ty.to_string()).join(", ")
      "(\{inner})"
    }
    Array(ty) => "Array[\{ty}]"
    Function(params, ret) => {
      let param_str = params.map(ty => ty.to_string()).join(", ")
      "(\{param_str}) -> \{ret}"
    }
    Defined(name) => name
  }
  logger.write_string(s)
}
