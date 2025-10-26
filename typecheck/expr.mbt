///|
pub(all) struct Expr {
  kind : ExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum ExprKind {
  ApplyExpr(ApplyExpr)
  BlockExpr(BlockExpr)
  NotExpr(Expr)
  NegExpr(Expr)
  BinaryExpr(BinaryOp, Expr, Expr)
  IfExpr(IfExpr)
} derive(Show)

///|
pub(all) enum BinaryOp {
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
  ShiftLeft // <<
  ShiftRight // >>
  Eq // ==
  NE // !=
  LT // <
  GT // >
  LE // <=
  GE // >=
  And // &&
  Or // ||
  BitAnd // &
  BitOr // |
} derive(Show, Eq)

///|
pub fn binop_is_cmp(bin_op : BinaryOp) -> Bool {
  match bin_op {
    Eq => true
    NE => true
    LT => true
    GT => true
    LE => true
    GE => true
    _ => false
  }
}

///|
pub fn binop_is_bitwise(bin_op : BinaryOp) -> Bool {
  bin_op is (BitAnd | BitOr)
}

///|
pub fn binop_is_arithmetic(bin_op : BinaryOp) -> Bool {
  match bin_op {
    Add => true
    Sub => true
    Mul => true
    Div => true
    Mod => true
    _ => false
  }
}

///|
pub fn parser_binop_to_typecheck_binop(
  tok_bin_op : @parser.BinaryOp,
) -> BinaryOp {
  match tok_bin_op {
    Add => Add
    Sub => Sub
    Mul => Mul
    Div => Div
    Mod => Mod
    ShiftLeft => ShiftLeft
    ShiftRight => ShiftRight
    Eq => Eq
    NE => NE
    LT => LT
    GT => GT
    LE => LE
    GE => GE
    And => And
    Or => Or
    BitAnd => BitAnd
    BitOr => BitOr
  }
}

///|
pub fn Context::check_expr(
  self : Self,
  expr : @parser.Expr,
) -> Expr raise TypeCheckError {
  let erpfx = "[Context::check_expr] type not satisfy"
  match expr.kind {
    ApplyExpr(app_expr) => {
      let expr = self.check_apply_expr(app_expr)
      Expr::{ kind: ExprKind::ApplyExpr(expr), ty: expr.ty }
    }
    NotExpr(not_expr) => {
      let inner_expr = self.check_expr(not_expr)
      if self.is_type_compatible(TypeKind::Bool, inner_expr.ty) {
        Expr::{ kind: ExprKind::NotExpr(inner_expr), ty: inner_expr.ty }
      } else {
        raise TypeCheckError(
          "\{erpfx}: \{inner_expr} expected: Bool, got: \{inner_expr.ty}",
        )
      }
    }
    NegExpr(inner_expr) => {
      let inner_expr = self.check_expr(inner_expr)
      match inner_expr.ty {
        Int | Double =>
          Expr::{ kind: ExprKind::NegExpr(inner_expr), ty: inner_expr.ty }
        _ =>
          raise TypeCheckError(
            "\{erpfx}: \{inner_expr} expected: Int | Double, got: \{inner_expr.ty}",
          )
      }
    }
    BinaryExpr(op, left, right) => {
      let op = parser_binop_to_typecheck_binop(op)
      let left = self.check_expr(left)
      let right = self.check_expr(right)
      if self.is_type_compatible(left.ty, right.ty) {
        if binop_is_bitwise(op) {
          if self.is_type_compatible(Int, left.ty) &&
            self.is_type_compatible(Int, right.ty) {
            Expr::{ kind: ExprKind::BinaryExpr(op, left, right), ty: Int }
          } else {
            raise TypeCheckError("\{erpfx}: bitwise op leaf type must be Int")
          }
        } else if op is And || op is Or {
          if self.is_type_compatible(Bool, left.ty) &&
            self.is_type_compatible(Bool, right.ty) {
            Expr::{ kind: ExprKind::BinaryExpr(op, left, right), ty: Bool }
          } else {
            raise TypeCheckError("\{erpfx}: logic op leaf type must be Bool")
          }
        } else {
          let (ty_non_var, ty_any) = match (left.ty, right.ty) {
            (TypeVar(_), TypeVar(_)) =>
              raise TypeCheckError(
                "\{erpfx}: BinaryExpr left or right must have one non-typevar",
              )
            (TypeVar(_) as tl, tr) => (tr, tl)
            r => r
          }
          if binop_is_arithmetic(op) {
            match ty_non_var {
              Int | Double as ty =>
                if self.is_type_compatible(ty_non_var, ty_any) {
                  Expr::{ kind: ExprKind::BinaryExpr(op, left, right), ty }
                } else {
                  raise TypeCheckError(
                    "\{erpfx}: arith op leaf expr type not compatible",
                  )
                }
              _ =>
                raise TypeCheckError(
                  "\{erpfx}: arith op leaf expr type must be one of Int | Double",
                )
            }
          } else if binop_is_cmp(op) {
            match ty_non_var {
              Int | Double | Bool =>
                if self.is_type_compatible(ty_non_var, ty_any) {
                  Expr::{
                    kind: ExprKind::BinaryExpr(op, left, right),
                    ty: Bool,
                  }
                } else {
                  raise TypeCheckError(
                    "\{erpfx}: cmp op leaf expr type not compatible",
                  )
                }
              _ =>
                raise TypeCheckError(
                  "\{erpfx}: cmp op leaf expr type must be one of Int | Double | Bool",
                )
            }
          } else {
            raise TypeCheckError("[Context::check_expr] unknown type op: \{op}")
          }
        }
      } else {
        raise TypeCheckError(
          "\{erpfx}: left[\{left.ty}] right[\{right.ty}] is not compatible",
        )
      }
    }
    _ =>
      raise TypeCheckError(
        "[Context::check_expr] not yet impl it: \{expr.kind}",
      )
  }
}
