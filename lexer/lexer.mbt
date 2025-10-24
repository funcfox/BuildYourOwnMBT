///|
pub(all) suberror TokenizeError String derive(Show)

///|
pub(all) enum Keyword {
  Fn
  Struct
  Let
  Mut
  If
  Else
  While
  For
  Return
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
} derive(Eq)

///|
pub impl Show for BinaryOp with output(self, logger) {
  let s = match self {
    Add => "+"
    Sub => "-"
    Mul => "*"
    Div => "/"
    Mod => "%"
    ShiftLeft => "<<"
    ShiftRight => ">>"
    Eq => "=="
    NE => "!="
    LT => "<"
    GT => ">"
    LE => "<="
    GE => ">="
    And => "&&"
    Or => "||"
    BitAnd => "&"
    BitOr => "|"
  }
  logger.write_string(s)
}

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq, ToJson)

///|
pub struct Token {
  kind : TokenKind
  // other info
} derive(Show, Eq)

///|
pub fn Token::new(kind : TokenKind) -> Token {
  Token::{ kind, }
}

///|
pub(all) enum TokenKind {
  Bool(Bool) // true, false
  Int(Int) // 1, 42, -100
  Double(Double)
  String(String) // "hello", "world"
  Keyword(Keyword)
  Upper(String)
  Lower(String)
  BinaryOp(BinaryOp) // +, -, *, /, %, =, ==, !=, <, >, <=, >=, &&, ||
  AssignOp(AssignOp) // =, +=, -=, *=, /=, %=
  Not // !
  Bracket(Char) // (, ), [, ], {, }
  Symbol(String) // . , ; : :: -> => 
  Wildcard // _
  EOF
} derive(Show, Eq)

///|
pub fn tokenize(code : String) -> Array[Token] raise TokenizeError {
  let result = []
  let mut rest = code[:]
  while !rest.is_empty() {
    rest = skip_whitespace(rest)
    rest = skip_comment(rest)
    if rest.is_empty() {
      break
    }
    let (tokk, rest_) = tokenize_ident(rest) catch {
      _ =>
        tokenize_symbol(rest) catch {
          _ => tokenize_number(rest) catch { _ => tokenize_string(rest) }
        }
    }
    rest = rest_
    result.push(Token::new(tokk))
  }
  result.push(Token::new(EOF))
  result
}

///|
fn skip_whitespace(toks : StringView) -> StringView {
  loop toks {
    [' ' | '\n', .. rest] => continue rest
    rest => break rest
  }
}

///|
fn skip_comment(toks : StringView) -> StringView {
  match toks {
    [.. "//", .. rest] =>
      loop rest {
        ['\n', .. rst] => break rst
        [_, .. rst] => continue rst
        [] => break []
      }
    _ => toks
  }
}

///|
fn tokenize_ident(
  toks : StringView,
) -> (TokenKind, StringView) raise TokenizeError {
  let (tokstr, rest) = loop ([], toks) {
    ([], ['a'..='z' | 'A'..='Z' | '_' as c, .. rest]) => continue ([c], rest)
    ([], [c, ..]) => raise TokenizeError("unable to tokenize \{c}")
    (result, ['a'..='z' | 'A'..='Z' | '0'..='9' | '_' as c, .. rest]) =>
      continue ([..result, c], rest)
    (result, rest) => break (result, rest)
  }
  if tokstr.is_empty() {
    raise TokenizeError("Expected identifier")
  }
  let (head_is_upper, _) = loop (false, tokstr[:]) {
    (_, ['a'..='z', .. rest]) => break (false, rest)
    (_, ['A'..='Z', .. rest]) => break (true, rest)
    (_, [_, .. rest]) => continue (false, rest)
    (_, []) => break (false, [])
  }
  let toks = @string.from_array(tokstr)
  if head_is_upper {
    (Upper(toks), rest)
  } else {
    // (Lower(toks), rest)
    let toks = match toks {
      "fn" => Keyword(Fn)
      "struct" => Keyword(Struct)
      "let" => Keyword(Let)
      "mut" => Keyword(Mut)
      "if" => Keyword(If)
      "else" => Keyword(Else)
      "while" => Keyword(While)
      "for" => Keyword(For)
      "return" => Keyword(Return)
      "true" => Bool(true)
      "false" => Bool(false)
      "_" => Wildcard
      _ => Lower(toks)
    }
    (toks, rest)
  }
}

///|
fn tokenize_symbol(
  toks : StringView,
) -> (TokenKind, StringView) raise TokenizeError {
  match toks {
    [.. "->", .. rest] => (Symbol("->"), rest)
    [.. "=>", .. rest] => (Symbol("=>"), rest)
    [.. "::", .. rest] => (Symbol("::"), rest)
    [.. "==", .. rest] => (BinaryOp(Eq), rest)
    [.. "!=", .. rest] => (BinaryOp(NE), rest)
    [.. "<=", .. rest] => (BinaryOp(LE), rest)
    [.. ">=", .. rest] => (BinaryOp(GE), rest)
    [.. "+=", .. rest] => (AssignOp(PlusAssign), rest)
    [.. "-=", .. rest] => (AssignOp(MinusAssign), rest)
    [.. "*=", .. rest] => (AssignOp(MultAssign), rest)
    [.. "/=", .. rest] => (AssignOp(DivAssign), rest)
    [.. "%=", .. rest] => (AssignOp(ModAssign), rest)
    [.. "<<", .. rest] => (BinaryOp(ShiftLeft), rest)
    [.. ">>", .. rest] => (BinaryOp(ShiftRight), rest)
    [.. "&&", .. rest] => (BinaryOp(And), rest)
    [.. "||", .. rest] => (BinaryOp(Or), rest)
    ['+', .. rest] => (BinaryOp(Add), rest)
    ['-', .. rest] => (BinaryOp(Sub), rest)
    ['*', .. rest] => (BinaryOp(Mul), rest)
    ['/', .. rest] => (BinaryOp(Div), rest)
    ['%', .. rest] => (BinaryOp(Mod), rest)
    ['<', .. rest] => (BinaryOp(LT), rest)
    ['>', .. rest] => (BinaryOp(GT), rest)
    ['&', .. rest] => (BinaryOp(BitAnd), rest)
    ['|', .. rest] => (BinaryOp(BitOr), rest)
    ['=', .. rest] => (AssignOp(Assign), rest)
    ['(', .. rest] => (Bracket('('), rest)
    [')', .. rest] => (Bracket(')'), rest)
    ['[', .. rest] => (Bracket('['), rest)
    [']', .. rest] => (Bracket(']'), rest)
    ['{', .. rest] => (Bracket('{'), rest)
    ['}', .. rest] => (Bracket('}'), rest)
    ['.', .. rest] => (Symbol("."), rest)
    [',', .. rest] => (Symbol(","), rest)
    [':', .. rest] => (Symbol(":"), rest)
    [';', .. rest] => (Symbol(";"), rest)
    ['!', .. rest] => (Not, rest)
    _ => raise TokenizeError("Excepted Symbol")
  }
}

///|
fn tokenize_number(
  toks : StringView,
) -> (TokenKind, StringView) raise TokenizeError {
  let (numsarr, have_dot, rest) = loop ([], false, toks) {
    (r, h, ['0'..='9' as c, .. rest]) => continue ([..r, c], h, rest)
    (r, false, ['.' as c, .. rest]) => continue ([..r, c], true, rest)
    (r, h, rest) => break (r, h, rest)
  }
  if numsarr.is_empty() {
    raise TokenizeError("Expected Number")
  }
  let nums = @string.from_array(numsarr)
  if have_dot {
    let num = @strconv.parse_double(nums) catch {
      e => raise TokenizeError(e.to_string())
    }
    (Double(num), rest)
  } else {
    let num = @strconv.parse_int(nums) catch {
      e => raise TokenizeError(e.to_string())
    }
    (Int(num), rest)
  }
}

///|
fn tokenize_string(
  toks : StringView,
) -> (TokenKind, StringView) raise TokenizeError {
  let (inner, flag, rest) = loop ([], false, toks) {
    (r, false, ['"', .. rest]) => continue (r, true, rest)
    (r, true, ['"', .. rest]) => break (r, false, rest)
    (r, true, [c, .. rest]) => continue ([..r, c], true, rest)
    (r, f, c) => break (r, f, c)
  }
  if inner.is_empty() {
    raise TokenizeError("Expected String")
  }
  if flag == true {
    raise TokenizeError("String is not close")
  }
  (String(@string.from_array(inner)), rest)
}
