///|
pub(all) struct LeftValue {
  kind : LeftValueKind
  ty : Type
} derive(Show)

///|
pub(all) enum LeftValueKind {
  Ident(String)
  ArrayAccess(LeftValue, Expr)
  FieldAccess(LeftValue, String)
} derive(Show)

///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show)

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq)

///|
pub fn AssignOp::from_parser_assign_op(op : @parser.AssignOp) -> AssignOp {
  match op {
    Assign => Assign
    PlusAssign => PlusAssign
    MinusAssign => MinusAssign
    MultAssign => MultAssign
    DivAssign => DivAssign
    ModAssign => ModAssign
  }
}

///|
pub fn Context::check_assign_stmt(
  self : Context,
  assign_stmt : @parser.AssignStmt,
) -> AssignStmt raise TypeCheckError {
  let op = AssignOp::from_parser_assign_op(assign_stmt.op)
  let expr = self.check_expr(assign_stmt.expr)
  let left_value = self.check_left_value(assign_stmt.left_value)
  if left_value.ty.mutable == false {
    raise TypeCheckError(
      "[Context::check_assign_stmt] left value must be mutable",
    )
  }
  if !self.is_type_compatible(left_value.ty.kind, expr.ty) {
    raise TypeCheckError(
      "[Context::check_assign_stmt] left value[\{left_value.ty.kind}] and expr[\{expr.ty}] type mismatch",
    )
  }
  match op {
    PlusAssign | MinusAssign | MultAssign | DivAssign => {
      let kind = self.get_typekind(left_value.ty.kind)
      if !(kind is Int || kind is Double) {
        raise TypeCheckError(
          "[Context::check_assign_stmt] '\{op}' must be Int or Double",
        )
      }
    }
    ModAssign => {
      let kind = self.get_typekind(left_value.ty.kind)
      if !(kind is Int) {
        raise TypeCheckError(
          "[Context::check_assign_stmt] '\{op}' type must be Int",
        )
      }
    }
    _ => ()
  }
  AssignStmt::{ left_value, op, expr }
}

///|
fn Context::check_left_value(
  self : Self,
  left_value : @parser.LeftValue,
) -> LeftValue raise TypeCheckError {
  match left_value.kind {
    Ident(name) => {
      let ty = self.type_env
        .get(name)
        .or_error(
          TypeCheckError(
            "[Context::check_left_value] unable to find variable type: \{name}",
          ),
        )
      LeftValue::{ kind: LeftValueKind::Ident(name), ty }
    }
    ArrayAccess(lval, index_expr) => {
      let lval = self.check_left_value(lval)
      let index_expr = self.check_expr(index_expr)
      if !self.is_type_compatible(TypeKind::Int, index_expr.ty) {
        raise TypeCheckError(
          "[Context::check_left_value] ArrayAccess index must be Int, current is \{index_expr.ty}",
        )
      }
      match lval.ty {
        { kind: Array(atk), .. } =>
          LeftValue::{
            kind: LeftValueKind::ArrayAccess(lval, index_expr),
            ty: Type::{ kind: self.get_typekind(atk), mutable: true },
          }
        _ =>
          raise TypeCheckError(
            "[Context::check_left_value] ArrayAccess lval must be Array[T]",
          )
      }
    }
    FieldAccess(lval, fname) => {
      let lval = self.check_left_value(lval)
      match lval.ty.kind {
        Struct(struct_name) => {
          let struct_def = self.struct_defs
            .get(struct_name)
            .or_error(
              TypeCheckError(
                "[Context::check_left_value] unknown struct name: \{struct_name}",
              ),
            )
          let field_idx = struct_def.fields
            .search_by(fn(fld) { fld.name == fname })
            .or_error(
              TypeCheckError(
                "[Context::check_left_value] \{struct_name}.\{fname} undefined",
              ),
            )
          let field = struct_def.fields[field_idx]
          LeftValue::{
            kind: LeftValueKind::FieldAccess(lval, fname),
            ty: field.ty,
          }
        }
        _ =>
          raise TypeCheckError(
            "[Context::check_left_value] FieldAccess lval must be Struct[T]",
          )
      }
    }
  }
}
