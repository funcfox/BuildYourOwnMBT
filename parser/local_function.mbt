///|
pub(all) struct LocalFunction {
  fname : String
  param_list : Array[(String, Type?)]
  ret_ty : Type?
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_local_function(
  tokens : ArrayView[Token],
) -> (LocalFunction, ArrayView[Token]) raise ParseError {
  let (ident, rest) = match tokens {
    [
      { kind: Keyword(Fn) },
      { kind: Lower(name) },
      { kind: Bracket('(') },
      .. rst,
    ] => (name, rst)
    _ => raise ParseError("expected 'fn [lower name]('")
  }
  let mut rest = rest
  let params = []
  while !(rest is [{ kind: Bracket(')') }, ..]) {
    let (pm, rest_) = parse_func_param(rest)
    params.push(pm)
    rest = match rest_ {
      [{ kind: Symbol(",") }, .. r] => r
      _ => rest_
    }
  }
  rest = match rest {
    [{ kind: Bracket(')') }, .. r] => r
    _ => raise ParseError("expected ')'")
  }
  let (ret_ty, rest) = match rest {
    [{ kind: Symbol("->") }, .. r] => {
      let (ty, rst) = parse_type(r)
      (Some(ty), rst)
    }
    r => (None, r)
  }
  let (body, rest) = parse_block_expr(rest)
  (LocalFunction::{ fname: ident, param_list: params, ret_ty, body }, rest)
}

///|
fn parse_func_param(
  tokens : ArrayView[Token],
) -> ((String, Type?), ArrayView[Token]) raise ParseError {
  let (name, rest) = match tokens {
    [{ kind: Lower(fname) }, .. rst] => (fname, rst)
    _ => raise ParseError("expected [lower name]")
  }
  let (ty, rest) = match rest {
    [{ kind: Symbol(":") }, .. rst] => {
      let (t, r) = parse_type(rst)
      (Some(t), r)
    }
    r => (None, r)
  }
  ((name, ty), rest)
}
