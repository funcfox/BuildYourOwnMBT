///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_if_expr(
  self : Context,
  if_expr : @parser.IfExpr,
) -> IfExpr raise TypeCheckError {
  let cond = self.check_expr(if_expr.cond)
  if !self.is_type_compatible(cond.ty, Bool) {
    raise TypeCheckError("[Context::check_if_expr] cond's type must be Bool")
  }
  let then_block = self.check_block_expr(if_expr.then_block)
  match if_expr.else_block {
    Some(else_block) => {
      let (else_block, blk_ty) : (Either[IfExpr, BlockExpr], TypeKind) = match
        else_block {
        Left(if_expr) => {
          let if_expr = self.check_if_expr(if_expr)
          (Either::Left(if_expr), if_expr.ty)
        }
        Right(block_expr) => {
          let block_expr = self.check_block_expr(block_expr)
          (Either::Right(block_expr), block_expr.ty)
        }
      }
      if !self.is_type_compatible(then_block.ty, blk_ty) {
        raise TypeCheckError(
          "[Context::check_if_expr] then_block's type must match else_block's type",
        )
      }
      let ret_ty = self.get_typekind(then_block.ty)
      IfExpr::{ cond, then_block, else_block: Some(else_block), ty: ret_ty }
    }
    None => {
      if !self.is_type_compatible(then_block.ty, Unit) {
        raise TypeCheckError(
          "[Context::check_if_expr] then_block's type must be Unit",
        )
      }
      IfExpr::{ cond, then_block, else_block: None, ty: Unit }
    }
  }
}
