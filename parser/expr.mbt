///|
pub(all) struct Expr {
  kind : ExprKind
} derive(Show, Eq)

///|
pub(all) enum ExprKind {
  ApplyExpr(ApplyExpr)
  BlockExpr(BlockExpr)
  NotExpr(Expr)
  NegExpr(Expr)
  BinaryExpr(BinaryOp, Expr, Expr)
  IfExpr(IfExpr)
} derive(Show, Eq)

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
fn BinaryOp::from_tok_binary_op(tok_bin_op : @lexer.BinaryOp) -> BinaryOp {
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
pub fn parse_expr(
  tokens : ArrayView[Token],
) -> (Expr, ArrayView[Token]) raise ParseError {
  // ignore(tokens)
  // ignore(BinaryOp::from_tok_binary_op)
  // ignore(BinaryOp::precedence)
  // let (app, rest) = parse_apply_expr(tokens)
  // (Expr::{ kind: ExprKind::ApplyExpr(app) }, rest)
  match tokens {
    [{ kind: Not }, .. rest] => {
      let (exp, rst) = parse_expr(rest)
      (Expr::{ kind: ExprKind::NotExpr(exp) }, rst)
    }
    [{ kind: BinaryOp(Sub) }, .. rest] => {
      let (exp, rst) = parse_expr(rest)
      (Expr::{ kind: ExprKind::NegExpr(exp) }, rst)
    }
    _ => {
      // let (app, rest) = parse_apply_expr(tokens)
      // (Expr::{ kind: ExprKind::ApplyExpr(app) }, rest)
      let mut rest = tokens
      let vals = []
      let ops = []
      // 先读入一个“操作数”
      let (app, rest_) = parse_apply_expr(rest)
      vals.push(Expr::{ kind: ExprKind::ApplyExpr(app) })
      rest = rest_
      // 然后循环：期望看到 (op, operand) 成对出现
      while rest is [{ kind: BinaryOp(_) }, ..] {
        // 读取并消费该二元运算符
        let (cop, rest_) = parse_binary_op(rest)
        rest = rest_
        // 取右操作数（如果语法允许可处理一元情况，这里按标准二元）
        let (rhs, rest_) = parse_apply_expr(rest)
        rest = rest_
        // vals.push(Expr::{ kind: ExprKind::ApplyExpr(rhs) })
        // 按优先级与结合性，决定是否规约栈顶
        while !ops.is_empty() {
          let top = ops[ops.length() - 1]
          let pt = BinaryOp::precedence(top)
          let pc = cop.precedence()
          if pt >= pc {
            reduce_once(vals, ops)
          } else {
            break
          }
        }
        // 当前运算符入栈
        ops.push(cop)
        vals.push(Expr::{ kind: ExprKind::ApplyExpr(rhs) })
      }
      // 输入耗尽后，把运算符栈清空
      while !ops.is_empty() {
        reduce_once(vals, ops)
      }
      // vals 应只剩一个表达式
      if vals.length() != 1 {
        raise ParseError("parse_expr: invalid state")
      }
      let exp = vals.pop().or_error(ParseError("parse_expr: need expr"))
      (exp, rest)
    }
  }
}

///|
fn reduce_once(
  vals : Array[Expr],
  ops : Array[BinaryOp],
) -> Unit raise ParseError {
  if ops.is_empty() || vals.length() < 2 {
    raise ParseError("syntax: missing operand or operator")
  }
  let op = ops.pop().or_error(ParseError("expected operator"))
  let rhs = vals.pop().or_error(ParseError("expected rhs"))
  let lhs = vals.pop().or_error(ParseError("expected lhs"))
  let expr = Expr::{ kind: ExprKind::BinaryExpr(op, lhs, rhs) }
  vals.push(expr)
}

///|
fn parse_binary_op(
  tokens : ArrayView[Token],
) -> (BinaryOp, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: BinaryOp(bop) }, .. rest] =>
      (BinaryOp::from_tok_binary_op(bop), rest)
    _ => raise ParseError("Expected Binary Operator")
  }
}

///|
fn BinaryOp::precedence(self : Self) -> Int {
  match self {
    Or => 1
    And => 2
    Eq | NE => 3
    LT | GT | LE | GE => 4
    BitOr => 5
    BitAnd => 7
    ShiftLeft | ShiftRight => 8
    Add | Sub => 9
    Mul | Div | Mod => 10
  }
}

// ///|
// fn Expr::show_binary_expr(
//   self : Self,
//   layer? : Int = 0,
// ) -> Unit raise ParseError {
//   fn print_leaf(hs : Expr, p : String) -> Unit raise ParseError {
//     match hs.kind {
//       BinaryExpr(_, _, _) => hs.show_binary_expr(layer=layer + 1)
//       ApplyExpr(k) =>
//         match k.kind {
//           AtomExpr(k) => println("\{p} \{k.kind}")
//           _ => raise ParseError("unable to print leaf \{hs}")
//         }
//       _ => raise ParseError("unable to print leaf \{hs}")
//     }
//   }

//   match self.kind {
//     BinaryExpr(op, lhs, rhs) => {
//       let pad = " ".repeat(layer * 2)
//       println("\{pad}\{op}")
//       print_leaf(lhs, pad)
//       print_leaf(rhs, pad)
//     }
//     _ => raise ParseError("unable to show \{self.kind}")
//   }
// }
