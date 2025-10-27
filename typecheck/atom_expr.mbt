///|
pub(all) struct AtomExpr {
  kind : AtomExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum AtomExprKind {
  Int(Int) // 1, 42, etc
  Double(Double) // 1.0, 3.14, etc
  Bool(Bool) // true | false
  String(String) // "hello", etc
  Ident(String) // var
  Unit // ()
  Paren(Expr) // (expr)
  Tuple(Array[Expr]) // (expr, expr, ...)
  Array(Array[Expr]) // [expr, expr, ...]
  ArrayMake(Expr, Expr) // Array::make(size, init)
  StructConstruct(StructConstructExpr) // StructName::{ field: expr, ... }
} derive(Show)

///|
pub fn Context::check_atom_expr(
  self : Self,
  atom_expr : @parser.AtomExpr,
) -> AtomExpr raise TypeCheckError {
  match atom_expr.kind {
    Int(n) => AtomExpr::{ kind: AtomExprKind::Int(n), ty: TypeKind::Int }
    Double(d) =>
      AtomExpr::{ kind: AtomExprKind::Double(d), ty: TypeKind::Double }
    Bool(b) => AtomExpr::{ kind: AtomExprKind::Bool(b), ty: TypeKind::Bool }
    String(s) =>
      AtomExpr::{ kind: AtomExprKind::String(s), ty: TypeKind::String }
    Ident(name) => {
      let ty = self.type_env
        .get(name)
        .map(fn(t) { t.kind })
        .or_error(TypeCheckError("unable to find type of \{name}"))
      AtomExpr::{ kind: AtomExprKind::Ident(name), ty }
    }
    Unit => AtomExpr::{ kind: AtomExprKind::Unit, ty: TypeKind::Unit }
    Paren(inner_expr) => {
      let inner_expr = self.check_expr(inner_expr)
      AtomExpr::{ kind: AtomExprKind::Paren(inner_expr), ty: inner_expr.ty }
    }
    Tuple(expr_arr) => {
      let expr_arr = expr_arr.map(fn(e) { self.check_expr(e) })
      let ty_arr = expr_arr.map(fn(e) { e.ty })
      AtomExpr::{
        kind: AtomExprKind::Tuple(expr_arr),
        ty: TypeKind::Tuple(ty_arr),
      }
    }
    Array(exprs) =>
      if exprs.is_empty() {
        // let (tid, ty) = self.new_typevar()
        // self.type_vars.set(tid, ty) // TODO: check here
        let ty = self.new_typevar()
        AtomExpr::{ kind: AtomExprKind::Array([]), ty: TypeKind::Array(ty) }
      } else {
        let exprs = exprs.map(fn(e) { self.check_expr(e) })
        let tys = exprs.map(fn(e) { e.ty })
        let mut arr_ty = tys[0]
        for t in tys[1:] {
          if !self.is_type_compatible(arr_ty, t) {
            raise TypeCheckError(
              "[Context::check_atom_expr] Array expr type not satisfy",
            )
          }
          arr_ty = match t {
            TypeVar(_) => arr_ty
            _ => t
          }
        }
        let arr_ty = self.get_typekind(arr_ty)
        AtomExpr::{
          kind: AtomExprKind::Array(exprs),
          ty: TypeKind::Array(arr_ty),
        }
      }
    ArrayMake(size_expr, init_expr) => {
      let size_expr = self.check_expr(size_expr)
      let init_expr = self.check_expr(init_expr)
      if !(size_expr.ty is Int) {
        raise TypeCheckError(
          "[Context::check_atom_expr]: ArrayMake size type must be Int, current: \{size_expr.ty}",
        )
      }
      AtomExpr::{
        kind: AtomExprKind::ArrayMake(size_expr, init_expr),
        ty: TypeKind::Array(init_expr.ty),
      }
    }
    StructConstruct(sc) => {
      let (kind, ty) = self.check_struct_construct_expr(sc)
      AtomExpr::{ kind, ty }
    }
    // _ =>
    //   raise TypeCheckError("check_atom_expr: not yet impl: \{atom_expr.kind}")
  }
}
