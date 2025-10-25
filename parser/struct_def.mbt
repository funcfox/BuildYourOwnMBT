///|
pub(all) struct StructDef {
  name : String
  fields : Array[StructField]
} derive(Show, Eq)

///|
pub(all) struct StructField {
  name : String
  is_mut : Bool
  ty : Type
} derive(Show, Eq)

///|
pub fn parse_struct_field(
  tokens : ArrayView[Token],
) -> (StructField, ArrayView[Token]) raise ParseError {
  match tokens {
    [{kind: Keyword(Mut)}, {kind: Lower(name)}, {kind: Symbol(":")}, ..rst] => {
      let (ty, r) = parse_type(rst)
      (StructField::{name, is_mut: true, ty}, r)
    }
    [{kind: Lower(name)}, {kind: Symbol(":")}, ..rst] => {
      let (ty, r) = parse_type(rst)
      (StructField::{name, is_mut: false, ty}, r)
    }
    _ => raise ParseError("expected (mut)? [lower name] : [type]")
  }
}

///|
pub fn parse_struct_def(
  tokens : ArrayView[Token],
) -> (StructDef, ArrayView[Token]) raise ParseError {
  let (name, rest) = match tokens {
    [
      { kind: Keyword(Struct) },
      { kind: Upper(fname) },
      { kind: Bracket('{') },
      .. rst,
    ] => (fname, rst)
    _ => raise ParseError("expected 'struct [lower name] {'")
  }
  let mut rest = rest
  let fields = []
  while !(rest is [{ kind: Bracket('}') }, ..]) {
    let (fd, rest_) = parse_struct_field(rest)
    fields.push(fd)
    rest = match rest_ {
      [{ kind: Symbol(";") }, .. r] => r
      _ => rest_
    }
  }
  rest = match rest {
    [{ kind: Bracket('}') }, .. r] => r
    _ => raise ParseError("expected '}'")
  }
  (StructDef::{ name, fields }, rest)
}
