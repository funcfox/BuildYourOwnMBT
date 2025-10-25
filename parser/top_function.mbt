///|
pub(all) struct Param {
  name : String
  ty : Type
} derive(Show, Eq)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : Type
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_param(
  tokens : ArrayView[Token],
) -> (Param, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Lower(name) }, { kind: Symbol(":") }, .. rest] => {
      let (ty, rst) = parse_type(rest)
      (Param::{ name, ty }, rst)
    }
    _ => raise ParseError("expected '[lower name] : '")
  }
}

///|
pub fn parse_top_function(
  tokens : ArrayView[Token],
) -> (TopFunction, ArrayView[Token]) raise ParseError {
  let (name, rest) = match tokens {
    [
      { kind: Keyword(Fn) },
      { kind: Lower(fname) },
      { kind: Bracket('(') },
      .. rst,
    ] => (fname, rst)
    [{ kind: Keyword(Fn) }, { kind: Lower("main") }, .. rst] => {
      let (body, r) = parse_block_expr(rst)
      return (
        TopFunction::{
          fname: "main",
          param_list: [],
          ret_ty: Type::{ kind: TypeKind::Unit },
          body,
        },
        r,
      )
    }
    _ => raise ParseError("expected 'fn [lower name](' or fn main { ... }")
  }
  let mut rest = rest
  let param_list = []
  while !(rest is [{ kind: Bracket(')') }, ..]) {
    let (pm, rst) = parse_param(rest)
    param_list.push(pm)
    rest = match rst {
      [{ kind: Symbol(",") }, .. r] => r
      _ => rst
    }
  }
  rest = match rest {
    [{ kind: Bracket(')') }, { kind: Symbol("->") }, .. rst] => rst
    _ => raise ParseError("expected ') ->'")
  }
  let (ret_type, rest) = parse_type(rest)
  let (body, rest) = parse_block_expr(rest)
  (TopFunction::{ fname: name, param_list, ret_ty: ret_type, body }, rest)
}
