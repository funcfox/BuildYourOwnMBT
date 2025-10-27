///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show)

///|
pub fn Context::check_struct_construct_expr(
  self : Self,
  sc_expr : @parser.StructConstructExpr,
) -> (AtomExprKind, TypeKind) raise TypeCheckError {
  let struct_def = self.struct_defs
    .get(sc_expr.name)
    .or_error(
      TypeCheckError(
        "[Context::check_struct_construct_expr] unable to find sturct \{sc_expr.name}",
      ),
    )
  if struct_def.fields.length() != sc_expr.fields.length() {
    raise TypeCheckError(
      "[Context::check_struct_construct_expr] num of \{sc_expr.name}'s fields mismatch",
    )
  }
  let fields = sc_expr.fields.map(fn(fd) {
    match fd {
      (fname, init_expr) => {
        let field_def_idx = struct_def.fields
          .search_by(fn(sf) { sf.name == fname })
          .or_error(
            TypeCheckError(
              "[Context::check_struct_construct_expr] unknown field \{fname} of \{sc_expr.name}",
            ),
          )
        let field_def = struct_def.fields[field_def_idx]
        let init_expr = self.check_expr(init_expr)
        if !self.is_type_compatible(init_expr.ty, field_def.ty.kind) {
          let type_info = "expected: \{field_def.ty.kind} current: \{init_expr.ty}"
          raise TypeCheckError(
            "[Context::check_struct_construct_expr] \{sc_expr.name}.\{fname} type mismatch, \{type_info}",
          )
        }
        (fname, init_expr)
      }
    }
  })
  (
    AtomExprKind::StructConstruct(StructConstructExpr::{
      name: sc_expr.name,
      fields,
    }),
    TypeKind::Struct(sc_expr.name),
  )
}
