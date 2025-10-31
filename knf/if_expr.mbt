///|
pub fn Context::if_expr_to_knf(
  self : Context,
  if_expr : @typecheck.IfExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  let stmts = []
  let (stmts_cond, expr_cond) = self.expr_to_knf(if_expr.cond)
  stmts.append(stmts_cond)
  let stmts_then_block = self.block_expr_to_knf(if_expr.then_block)
  let stmts_else_block = match if_expr.else_block {
    Some(Left(else_if_expr)) => {
      // // 处理 else if：递归调用 if_expr_to_knf
      let (else_stmts, nested_if_knf) = self.if_expr_to_knf(else_if_expr)
      stmts.append(else_stmts)
      let ty = self.typekind_to_knf(else_if_expr.ty)
      KnfBlock::{ stmts: [KnfStmt::ExprStmt(nested_if_knf)], ty }
    }
    Some(Right(else_block_expr)) => self.block_expr_to_knf(else_block_expr)
    // // 处理 else 块：使用 block_expr_to_knf
    // self.block_expr_to_knf(else_block_expr)
    None => KnfBlock::{ stmts: [], ty: Type::Unit }
    // 没有 else：创建空的 KnfBlock
    // KnfBlock::{ stmts: [] }
  }
  let result = KnfExpr::If(expr_cond, stmts_then_block, stmts_else_block)
  (stmts, result)
}
