///|
pub(all) struct LetStmt {
  pattern : Pattern
  ty : TypeKind
  expr : Expr
} derive(Show)

///|
pub(all) struct Pattern {
  kind : PatternKind
} derive(Show, Eq)

///|
pub(all) enum PatternKind {
  Wildcard
  Ident(String)
  Tuple(Array[Pattern])
} derive(Show, Eq)

///|
pub fn Context::check_let_stmt(
  self : Context,
  let_stmt : @parser.LetStmt,
) -> LetStmt raise TypeCheckError {
  // ignore(self)
  // ignore(let_stmt)
  // raise TypeCheckError("check_let_stmt not implemented")
  let expr = self.check_expr(let_stmt.expr)
  let kind = match let_stmt.ty {
    Some(pty) => {
      let ty = self.check_parser_typekind(pty.kind)
      if self.is_type_compatible(ty, expr.ty) {
        ty
      } else {
        raise TypeCheckError(
          "[Context::check_let_stmt] sig[\{ty}] != expr[\{expr.ty}]",
        )
      }
    }
    None => self.get_typekind(expr.ty)
  }
  let pattern = self.bind_pattern_type(let_stmt.pattern, kind)
  LetStmt::{ pattern, ty: kind, expr }
  // match let_stmt.pattern.kind {
  //   Wildcard => {
  //     let ltk = match let_stmt.ty {
  //       Some(t) => {
  //         let tk = self.check_parser_typekind(t.kind)
  //         if self.is_type_compatible(tk, expr.ty) {
  //           self.get_typekind(tk)
  //         } else {
  //           raise TypeCheckError(
  //             "[Context::check_let_stmt] sig[\{tk}] and expr[\{expr.ty}] type not match",
  //           )
  //         }
  //       }
  //       None => self.get_typekind(expr.ty)
  //     }
  //     LetStmt::{
  //       pattern: Pattern::{ kind: PatternKind::Wildcard },
  //       ty: ltk,
  //       expr,
  //     }
  //   }
  //   _ =>
  //     raise TypeCheckError(
  //       "[Context::check_let_stmt] pattern \{let_stmt.pattern.kind} is not impl",
  //     )
  // }
}

///|
fn Context::bind_pattern_type(
  self : Self,
  pattern : @parser.Pattern,
  ty : TypeKind,
) -> Pattern raise TypeCheckError {
  match (pattern.kind, ty) {
    (Ident(name), tt) => {
      let kind = self.get_typekind(tt)
      self.type_env.set(name, Type::{ kind, mutable: false })
      Pattern::{ kind: PatternKind::Ident(name) }
    }
    (Wildcard, _) => Pattern::{ kind: PatternKind::Wildcard }
    (Tuple(pattern_arr), Tuple(ty_arr)) => {
      let pat_arr = loop (pattern_arr[:], ty_arr[:], []) {
        ([], [_, ..], _) | ([_, ..], [], _) =>
          raise TypeCheckError(
            "[Context::bind_pattern_type] pattern \{pattern_arr} and \{ty_arr} not match",
          )
        ([], [], res) => break res
        ([p, .. prest], [t, .. trest], res) => {
          let pp = self.bind_pattern_type(p, t)
          let res = [..res, pp]
          continue (prest, trest, res)
        }
      }
      Pattern::{ kind: PatternKind::Tuple(pat_arr) }
    }
    _ =>
      raise TypeCheckError(
        "[Context::bind_pattern_type] pattern \{pattern.kind} and \{ty} not match",
      )
  }
}
