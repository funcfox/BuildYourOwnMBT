///|
pub(all) struct LetMutStmt {
  name : String
  ty : Type
  expr : Expr
} derive(Show)

///|
pub fn Context::check_let_mut_stmt(
  self : Context,
  stmt : @parser.LetMutStmt,
) -> LetMutStmt raise TypeCheckError {
  let expr = self.check_expr(stmt.expr)
  let tykd = match stmt.ty {
    Some(t) => {
      let expr_ty = self.get_typekind(expr.ty)
      let ann_ty = self.check_parser_type(t)
      if self.is_type_compatible(expr_ty, ann_ty.kind) {
        ann_ty.kind
      } else {
        let ann = "annontate type[\{ann_ty.kind}]"
        let exp = "expr type[\{expr_ty}]"
        raise TypeCheckError(
          "[Context::check_let_mut_stmt] \{ann} not satisfy \{exp}",
        )
      }
    }
    None => expr.ty
  }
  let ty = Type::{ kind: tykd, mutable: true }
  self.type_env.set(stmt.name, ty)
  LetMutStmt::{ name: stmt.name, ty, expr }
}
