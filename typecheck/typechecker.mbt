///|
pub fn typecheck(program : @parser.Program) -> Program raise TypeCheckError {
  let ctx = Context::new()
  // add build-in function type
  ctx.func_types.set("print_int", TypeKind::Function([Int], Unit))
  ctx.type_env.set("print_int", {kind: TypeKind::Function([Int], Unit), mutable: false})
  let checked_program = ctx.check_program(program)
  let ret = ctx.substitute_type_var(checked_program)
  ret
}

///|
pub fn Context::substitute_type_var(
  self : Context,
  program : Program,
) -> Program raise TypeCheckError {
  let top_lets = self.substitute_top_lets(program.top_lets)
  let top_functions = self.substitute_top_functions(program.top_functions)
  let struct_defs = self.substitute_struct_defs(program.struct_defs)
  Program::{ top_lets, top_functions, struct_defs }
}

///|
fn Context::substitute_struct_defs(
  self : Self,
  struct_defs : Map[String, StructDef],
) -> Map[String, StructDef] raise TypeCheckError {
  let result = Map::new()
  for it in struct_defs.iter() {
    let sstrd = self.substitute_struct_def(it.1)
    result.set(it.0, sstrd)
  }
  result
}

///|
fn Context::substitute_struct_def(
  self : Self,
  struct_def : StructDef,
) -> StructDef raise TypeCheckError {
  let fields = struct_def.fields.map(fn(sf) {
    StructField::{ name: sf.name, ty: self.ensure_type_is_real(sf.ty) }
  })
  StructDef::{ name: struct_def.name, fields }
}

///|
fn Context::substitute_top_functions(
  self : Self,
  top_functions : Map[String, TopFunction],
) -> Map[String, TopFunction] raise TypeCheckError {
  let stfs = Map::new()
  for it in top_functions.iter() {
    let stf = self.substitute_top_function(it.1)
    stfs.set(it.0, stf)
  }
  stfs
}

///|
fn Context::substitute_top_function(
  self : Self,
  top_function : TopFunction,
) -> TopFunction raise TypeCheckError {
  TopFunction::{
    fname: top_function.fname,
    param_list: top_function.param_list.map(fn(p) {
      Param::{ name: p.name, ty: self.ensure_typekind_is_real(p.ty) }
    }),
    ret_ty: self.ensure_typekind_is_real(top_function.ret_ty),
    body: self.substitute_block_expr(top_function.body),
  }
}

///|
fn Context::substitute_top_lets(
  self : Self,
  top_lets : Map[String, TopLet],
) -> Map[String, TopLet] raise TypeCheckError {
  let sub_top_lets = Map::new()
  top_lets.each(fn(name, tl) {
    let stl = TopLet::{
      name: tl.name,
      ty: Type::{
        kind: self.ensure_typekind_is_real(tl.ty.kind),
        mutable: tl.ty.mutable,
      },
      expr: self.substitute_expr(tl.expr),
    }
    sub_top_lets.set(name, stl)
  })
  sub_top_lets
}

///|
fn Context::substitute_expr(
  self : Self,
  expr : Expr,
) -> Expr raise TypeCheckError {
  Expr::{
    kind: self.substitute_exprkind(expr.kind),
    ty: self.ensure_typekind_is_real(expr.ty),
  }
}

///|
fn Context::substitute_exprkind(
  self : Self,
  kind : ExprKind,
) -> ExprKind raise TypeCheckError {
  match kind {
    BinaryExpr(op, left, right) =>
      BinaryExpr(op, self.substitute_expr(left), self.substitute_expr(right))
    NegExpr(expr) => NegExpr(self.substitute_expr(expr))
    NotExpr(expr) => NotExpr(self.substitute_expr(expr))
    BlockExpr(block) => BlockExpr(self.substitute_block_expr(block))
    ApplyExpr(app_expr) => ApplyExpr(self.substitute_apply_expr(app_expr))
    IfExpr(if_expr) => IfExpr(self.substitute_if_expr(if_expr))
  }
}

///|
fn Context::substitute_if_expr(
  self : Self,
  if_expr : IfExpr,
) -> IfExpr raise TypeCheckError {
  let cond = self.substitute_expr(if_expr.cond)
  let then_block = self.substitute_block_expr(if_expr.then_block)
  let else_block = if_expr.else_block.map(fn(eblk) {
    match eblk {
      Left(ie) => Either::Left(self.substitute_if_expr(ie))
      Right(blk) => Either::Right(self.substitute_block_expr(blk))
    }
  })
  let ty = self.ensure_typekind_is_real(if_expr.ty)
  IfExpr::{ cond, then_block, else_block, ty }
}

///|
fn Context::substitute_block_expr(
  self : Self,
  block : BlockExpr,
) -> BlockExpr raise TypeCheckError {
  let stmts = block.stmts.map(fn(stm) { self.substitute_stmt(stm) })
  let ty = self.ensure_typekind_is_real(block.ty)
  BlockExpr::{ stmts, ty }
}

///|
fn Context::substitute_stmt(
  self : Self,
  stmt : Stmt,
) -> Stmt raise TypeCheckError {
  let kind = match stmt.kind {
    ReturnStmt(expr_) =>
      ReturnStmt(
        match expr_ {
          Some(expr) => Some(self.substitute_expr(expr))
          None => None
        },
      )
    ExprStmt(expr) => ExprStmt(self.substitute_expr(expr))
    WhileStmt(stmt_kind) => {
      let while_stmt = WhileStmt::{
        cond: self.substitute_expr(stmt_kind.cond),
        body: self.substitute_block_expr(stmt_kind.body),
      }
      WhileStmt(while_stmt)
    }
    AssignStmt(assign_stmt) => {
      let left_value = self.substitute_left_value(assign_stmt.left_value)
      let expr = self.substitute_expr(assign_stmt.expr)
      let ass_stmt = AssignStmt::{ left_value, op: assign_stmt.op, expr }
      AssignStmt(ass_stmt)
    }
    LetMutStmt(lm_stmt) => {
      let ty = self.ensure_type_is_real(lm_stmt.ty)
      let expr = self.substitute_expr(lm_stmt.expr)
      LetMutStmt(LetMutStmt::{ name: lm_stmt.name, ty, expr })
    }
    LetStmt(lst) =>
      LetStmt(LetStmt::{
        pattern: lst.pattern,
        ty: self.ensure_typekind_is_real(lst.ty),
        expr: self.substitute_expr(lst.expr),
      })
    LocalFunction(lf) => {
      let param_list = lf.param_list.map(fn(param) {
        (param.0, self.ensure_type_is_real(param.1))
      })
      let body = self.substitute_block_expr(lf.body)
      LocalFunction(LocalFunction::{
        fname: lf.fname,
        param_list,
        ret_ty: self.ensure_type_is_real(lf.ret_ty),
        body,
      })
    }
  }
  Stmt::{ kind, }
}

///|
fn Context::substitute_left_value(
  self : Self,
  left_value : LeftValue,
) -> LeftValue raise TypeCheckError {
  let kind = match left_value.kind {
    ArrayAccess(lv, e) =>
      LeftValueKind::ArrayAccess(
        self.substitute_left_value(lv),
        self.substitute_expr(e),
      )
    Ident(n) => Ident(n)
    FieldAccess(lv, n) => FieldAccess(self.substitute_left_value(lv), n)
  }
  LeftValue::{ kind, ty: self.ensure_type_is_real(left_value.ty) }
}

///|
fn Context::substitute_apply_expr(
  self : Self,
  app_expr : ApplyExpr,
) -> ApplyExpr raise TypeCheckError {
  let kind = match app_expr.kind {
    FieldAccess(app, str) =>
      ApplyExprKind::FieldAccess(self.substitute_apply_expr(app), str)
    ArrayAccess(ae, expr) =>
      ArrayAccess(self.substitute_apply_expr(ae), self.substitute_expr(expr))
    AtomExpr(atm) => AtomExpr(self.substitute_atom_expr(atm))
    Call(ae, exprs) =>
      Call(
        self.substitute_apply_expr(ae),
        exprs.map(fn(e) { self.substitute_expr(e) }),
      )
  }
  ApplyExpr::{ kind, ty: self.ensure_typekind_is_real(app_expr.ty) }
}

///|
fn Context::substitute_atom_expr(
  self : Self,
  atom : AtomExpr,
) -> AtomExpr raise TypeCheckError {
  let kind = match atom.kind {
    ArrayMake(size, init) =>
      ArrayMake(self.substitute_expr(size), self.substitute_expr(init))
    Array(exprs) => Array(exprs.map(fn(e) { self.substitute_expr(e) }))
    Tuple(exprs) => Tuple(exprs.map(fn(e) { self.substitute_expr(e) }))
    Paren(expr) => Paren(self.substitute_expr(expr))
    StructConstruct(sce) =>
      StructConstruct(StructConstructExpr::{
        name: sce.name,
        fields: sce.fields.map(fn(fp) { (fp.0, self.substitute_expr(fp.1)) }),
      })
    r => r
  }
  let ty = self.ensure_typekind_is_real(atom.ty)
  AtomExpr::{ kind, ty }
}

///|
fn Context::ensure_typekind_is_real(
  self : Self,
  kind : TypeKind,
) -> TypeKind raise TypeCheckError {
  match kind {
    TypeVar(_) => {
      let k = self.get_typekind(kind)
      if k is TypeVar(_) {
        raise TypeCheckError(
          "[Context::ensure_typekind_is_real] unable to get real type of \{k}",
        )
      }
      k
    }
    Function(arg_tys, ret_ty) =>
      Function(
        arg_tys.map(fn(k) { self.ensure_typekind_is_real(k) }),
        self.ensure_typekind_is_real(ret_ty),
      )
    Array(tk) => Array(self.ensure_typekind_is_real(tk))
    Tuple(etks) => Tuple(etks.map(fn(k) { self.ensure_typekind_is_real(k) }))
    _ => kind
  }
}

///|
fn Context::ensure_type_is_real(
  self : Self,
  ty : Type,
) -> Type raise TypeCheckError {
  Type::{ kind: self.ensure_typekind_is_real(ty.kind), mutable: ty.mutable }
}
