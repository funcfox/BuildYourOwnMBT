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
        } else if binop_is_arithmetic(op) {
          let ret_ty = self.check_rettype_is_int_or_double(left.ty, right.ty)
          Expr::{ kind: ExprKind::BinaryExpr(op, left, right), ty: ret_ty }
        } else if binop_is_cmp(op) {
          let _ = self.check_rettype_is_int_or_double(left.ty, right.ty) // TODO: check here: cmp op's leaf type can be Int | Double | Bool
          Expr::{ kind: ExprKind::BinaryExpr(op, left, right), ty: Bool }
        } else {
          raise TypeCheckError("[Context::check_expr] unknown type op: \{op}")
        }
      } else {
        raise TypeCheckError(
          "\{erpfx}: left[\{left.ty}] right[\{right.ty}] is not compatible",
        )
      }
    }
    IfExpr(if_expr) => {
      let if_expr = self.check_if_expr(if_expr)
      Expr::{ kind: IfExpr(if_expr), ty: if_expr.ty }
    }
    _ =>
      raise TypeCheckError(
        "[Context::check_expr] not yet impl it: \{expr.kind}",
      )
  }
}

///|
fn Context::check_rettype_is_int_or_double(
  self : Self,
  ty_left : TypeKind,
  ty_right : TypeKind,
) -> TypeKind raise TypeCheckError {
  let pfx = "[Context::check_rettype_is_int_or_double]"
  let ty_left = self.get_typekind(ty_left)
  let ty_right = self.get_typekind(ty_right)
  if !self.is_type_compatible(ty_left, ty_right) {
    raise TypeCheckError(
      "\{pfx} left[\{ty_left}] is not match right[\{ty_right}]",
    )
  }
  let (ty, vty) = match (ty_left, ty_right) {
    (TypeVar(_), TypeVar(_)) => return ty_left
    (TypeVar(_) as vty, ty) => (ty, vty)
    (ty, TypeVar(_) as vty) => (ty, vty)
    (lty, rty) =>
      if self.is_type_compatible(lty, rty) {
        return lty
      } else {
        raise TypeCheckError("\{pfx} left[\{lty}] is not match right[\{rty}]")
      }
  }
  match ty {
    Int | Double =>
      if self.is_type_compatible(ty, vty) {
        ty
      } else {
        raise TypeCheckError(
          "\{pfx} left[\{ty_left}] is not match right[\{ty_right}]",
        )
      }
    _ => raise TypeCheckError("\{pfx} type must be Int or Double")
  }
}
