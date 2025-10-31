///|
pub(all) struct KnfTopLet {
  name : Name
  ty : Type
  expr : KnfExpr
}

///|
pub fn Context::top_let_to_knf(
  self : Context,
  top_let : @typecheck.TopLet,
) -> KnfTopLet raise KnfTransformError {
  guard self.globals.get(top_let.name) is None else {
    raise KnfTransformError("\{top_let.name} is existing in global")
  }
  let ty = self.typekind_to_knf(top_let.expr.ty)
  let (stmts, expr) = self.expr_to_knf(top_let.expr)
  guard stmts.length() == 0 else {
    raise KnfTransformError(
      "expr trans stmts must be empty (TODO: check impl detial)",
    )
  }
  let name = self.add_new_name(top_let.name, ty)
  self.globals.set(top_let.name, ty)
  KnfTopLet::{ name, ty, expr }
}

///|
pub impl Show for KnfTopLet with output(self, logger) {
  let { name, ty, expr } = self
  logger.write_string("let \{name} : \{ty} = \{expr};")
}
