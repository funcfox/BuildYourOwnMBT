///|
pub(all) struct ApplyExpr {
  kind : ApplyExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  Call(ApplyExpr, Array[Expr])
} derive(Show)

///|
pub fn Context::check_apply_expr(
  self : Self,
  apply_expr : @parser.ApplyExpr,
) -> ApplyExpr raise TypeCheckError {
  match apply_expr.kind {
    AtomExpr(a) => {
      let atm = self.check_atom_expr(a)
      ApplyExpr::{ kind: ApplyExprKind::AtomExpr(atm), ty: atm.ty }
    }
    ArrayAccess(array_expr, index_expr) => {
      let array_expr = self.check_apply_expr(array_expr)
      let index_expr = self.check_expr(index_expr)
      match (array_expr.ty, index_expr.ty) {
        (Array(ty), Int) =>
          ApplyExpr::{
            kind: ApplyExprKind::ArrayAccess(array_expr, index_expr),
            ty,
          }
        _ => {
          let expect = "ArrayAccess(Array[T], Int)"
          let actual = "ArrayAccess(\{array_expr.ty}, \{index_expr.ty})"
          raise TypeCheckError(
            "[Context::check_apply_expr]: type must be \{expect}, current is \{actual}",
          )
        }
      }
    }
    FieldAccess(obj_expr, fname) => {
      let obj_expr = self.check_apply_expr(obj_expr)
      match obj_expr.ty {
        Struct(struct_name) => {
          let struct_def = self.struct_defs
            .get(struct_name)
            .or_error(
              TypeCheckError(
                "[Context::check_apply_expr] unable to find struct \{struct_name}",
              ),
            )
          let field_id = struct_def.fields
            .search_by(fn(sf) { sf.name == fname })
            .or_error(
              TypeCheckError(
                "[Context::check_apply_expr] \{struct_name}.\{fname} doesn't exist",
              ),
            )
          let field_type = struct_def.fields[field_id].ty
          ApplyExpr::{
            kind: ApplyExprKind::FieldAccess(obj_expr, fname),
            ty: field_type.kind,
          }
        }
        Array(t) => {
          // 编译器内置方法
          let ret_ty = match fname {
            "push" => TypeKind::Function([t], TypeKind::Unit)
            "pop" => TypeKind::Function([], t) // TODO: check here
            "length" => TypeKind::Function([], TypeKind::Int)
            _ =>
              raise TypeCheckError(
                "[Context::check_apply_expr] Array.\{fname} doesn't exist",
              )
          }
          ApplyExpr::{
            kind: ApplyExprKind::FieldAccess(obj_expr, fname),
            ty: ret_ty,
          }
        }
        _ => {
          let expected = "expected Struct(_) or Array(_)"
          let actually = "current: \{obj_expr.ty}"
          raise TypeCheckError(
            "[Context::check_apply_expr] FieldAccess \{expected}, \{actually}",
          )
        }
      }
    }
    Call(callee_expr, arg_exprs) => {
      let callee_expr = self.check_apply_expr(callee_expr)
      let arg_exprs = arg_exprs.map(fn(e) { self.check_expr(e) })
      match callee_expr.ty {
        Function(args_ty, ret_ty) => {
          let cmpt = loop (arg_exprs[:], args_ty[:]) {
            ([], []) => break true
            ([_, ..], []) => break false
            ([], [_, ..]) => break false
            ([ae, .. arg_exp_rest], [at, .. arg_ty_rest]) =>
              if self.is_type_compatible(ae.ty, at) {
                continue (arg_exp_rest, arg_ty_rest)
              } else {
                break false
              }
          }
          if !cmpt {
            raise TypeCheckError(
              "[Context::check_apply_expr] function arg type is not compatible",
            )
          }
          let ret_ty = match ret_ty {
            TypeVar(tid) => self.query_typevar(tid)
            _ => ret_ty
          }
          ApplyExpr::{
            kind: ApplyExprKind::Call(callee_expr, arg_exprs),
            ty: ret_ty,
          }
        }
        _ =>
          raise TypeCheckError(
            "[Context::check_apply_expr] callee must be Function, current is \{callee_expr.ty}",
          )
      }
    }
    // _ =>
    //   raise TypeCheckError(
    //     "Context::check_apply_expr: not yet impl: \{apply_expr.kind}",
    //   )
  }
}
