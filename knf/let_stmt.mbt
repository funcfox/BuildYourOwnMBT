///|
pub fn Context::let_stmt_to_knf(
  self : Context,
  let_stmt : @typecheck.LetStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let (stmts, expr) = self.expr_to_knf(let_stmt.expr)
  let ty = self.typekind_to_knf(let_stmt.expr.ty)
  let stmts_let = self.bind_pattern_to_expr(let_stmt.pattern, expr, ty)
  stmts.add(stmts_let)
}

///|
fn Context::bind_pattern_to_expr(
  self : Self,
  pattern : @typecheck.Pattern,
  expr : KnfExpr,
  ty : Type,
) -> Array[KnfStmt] raise KnfTransformError {
  match (pattern.kind, expr) {
    (Ident(name), e) => {
      let name = self.add_new_name(name, ty)
      [Let(name, ty, e)]
    }
    (Wildcard, expr) => {
      let name = Name::wildcard()
      [Let(name, ty, expr)]
    }
    (Tuple(patterns), TupleLiteral(names)) => {
      // println("bind: pattern(\{pattern}) = expr(\{expr})")
      let stmts = []
      for pn in patterns.zip(names) {
        // println("sub-bind: pattern(\{pn.0}) = expr(\{pn.1})")
        let ty = self.name_env
          .get_name_type(pn.1)
          .or_error(KnfTransformError("unable to find \{pn.1}'s name"))
        let stmts_ = self.bind_pattern_to_expr(
          pn.0,
          KnfExpr::Ident(pn.1),
          ty,
        )
        stmts.append(stmts_)
      }
      stmts
    }
    (Tuple(patterns), Ident(name)) => {
      let ty_expr = self.name_env
        .get_name_type(name)
        .or_error(KnfTransformError("unable to find type of \{name}"))
      match ty_expr {
        Tuple(tys) => {
          let result = []
          for idx, it in patterns.zip(tys).iter2() {
            let name_part = self.add_temp(it.1)
            result.push(Let(name_part, it.1, TupleAccess(name, idx)))
            let stmt = self.bind_pattern_to_expr(it.0, Ident(name_part), it.1)
            result.append(stmt)
          }
          result
        }
        _ =>
          raise KnfTransformError(
            "'let' right part must be Tuple, current is \{ty_expr}",
          )
      }
    }
    _ => raise KnfTransformError("pattern mismatch")
  }
}
