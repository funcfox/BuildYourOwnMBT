
let challenge_names = [
  "tokenize_ident_test",
  "tokenize_keyword_test",
  "tokenize_comments_test",
  "tokenize_symbols_test",
  "tokenize_operator_test",
  "tokenize_integer_test",
  "tokenize_float_test",
  "tokenize_string_test",
  "tokenize_code_test",
  "parse_type_test",
  "parse_simple_atom_expr_test",
  "parse_simple_apply_expr_test",
  "parse_simple_expr_test",
  "parse_simple_unary_expr_test",
  "parse_simple_binary_expr_test",
  "parse_paren_expr_test",
  "parse_array_make_test",
  "parse_array_expr_test",
  "parse_simple_array_access_expr_test",
  "parse_simple_call_expr_test",
  "parse_simple_field_access_expr_test",
  "parse_complex_apply_expr_test",
  "parse_pattern_test",
  "parse_let_stmt_test",
  "parse_let_mut_stmt_test",
  "parse_left_value_test",
  "parse_assign_stmt_test",
  "parse_simple_stmt_test",
  "parse_block_expr_test",
  "parse_if_expr_test",
  "parse_while_stmt_test",
  "parse_complex_expr_test",
  "parse_local_function_test",
  "parse_top_function_test",
  "parse_struct_def_test",
  "parse_struct_construct_test",
  "parse_top_let_test",
  "parse_program_test",
]

struct Challenge {
  name: String
  dir: String
}

async fn Challenge::mbt_existed(self: Self) -> Bool {
  @fs.exists("\{self.dir}/\{self.name}.mbt")
}

async fn Challenge::extract(self: Self) -> Unit {
  let _ = @process.collect_output_merged("unzip", ["data.zip", "\{self.name}.mbt", "-d", self.dir])
}

async fn Challenge::is_passed(self: Self) -> Bool {
  // check if self.dir/self.name.mbt exists
  if !self.mbt_existed() {
    return false
  }
  let (_, _) = @process.collect_output_merged("moon", ["clean"]) 
  let (_, output) = @process.collect_output_merged("moon", ["test", "--verbose", "-p", self.dir, "-f", "\{self.name}.mbt"]) 
  let output = output.text()
  let head = output.find("[moonbitlang/MiniMoonbit] test ")
  if head is None {
    return false
  }
  let head = head.unwrap()
  let output = output[head:]
  if !output.contains(self.name) {
    return false
  }
  let mut all_passed = true
  let mut slice = output[:]
  while slice.find(self.name) is Some(idx) {
    slice = output[idx:]
    let next_newline = slice.find("\n")
    if next_newline is None {
      break
    }
    let next_newline = next_newline.unwrap()
    let slice2 = slice[:next_newline]
    all_passed = all_passed && slice2.has_suffix("ok")
    break
  }

  all_passed
}

async fn construct_challenges() -> Array[Challenge] {
  let challenges = Array::new()
  if !@fs.exists("data.zip") {
    println(">>>>>>> Error: data.zip not found")
    return challenges
  }
  let (_, msg) = @process.collect_output_merged("unzip", ["-l", "data.zip"])
  let msg = msg.text()
  for name in challenge_names {
    let mbt_name = "\{name}.mbt"
    if !msg.contains(mbt_name) {
      println(">>>>>>> Error: data.zip does not contain \{mbt_name}")
      return challenges
    }
  }
  for name in challenge_names {
    let dir = if name.has_prefix("tokenize") {
      "lexer"
    } else if name.has_prefix("parse") {
      "parser"
    } else if name.has_prefix("typecheck") {
      "typecheck"
    } else if name.has_prefix("knf") {
      "knf"
    } else if name.has_prefix("interp") {
      "interp"
    } else if name.has_prefix("codegen") {
      "codegen"
    } else { 
      println("Unknown challenge: \{name}")
      panic()
    }
    challenges.push(Challenge::{ name, dir})
  }
  challenges
}

async fn main {
  let challenges = construct_challenges()

  // find first not passed challenge
  println("检查挑战进度...")
  let mut first_not_passed : Challenge? = None
  let mut challenge_idx = 0
  for i, challenge in challenges {
    if !challenge.is_passed() {
      first_not_passed = Some(challenge)
      challenge_idx = i
      break
    }
  }

  if first_not_passed is None {
    print_conguratulation()
    return
  }

  let first_not_passed = first_not_passed.unwrap()
  println("当前挑战进度为：\{first_not_passed.name}")

  if first_not_passed.mbt_existed() {
    println("\{first_not_passed.name}.mbt 测试失败了，加油，你可以的！")
    return
  }

  if first_not_passed.name == challenge_names[0] {
    print_start()
  }

  let challenge_view = challenges[challenge_idx:]
  for challenge in challenge_view {
    println("为你激活下一项挑战，位于 \{challenge.dir}/\{challenge.name}.mbt ...")
    challenge.extract()
    if challenge.is_passed() {
      println("\{challenge.name} 也通过了，干得漂亮！")
      continue
    } else {
      let dir_name = challenge.dir
      println("下一项挑战位于 \{dir_name}/\{challenge.name}.mbt, 加油！")
      return
    }
  }
  print_conguratulation()
}

fn print_start() -> Unit {
  println("========================================================")
  println("🚀 欢迎来到 MiniMoonBit 挑战！")
  println("在这里，你将逐步完成一系列挑战，最终实现一个简化版的 MoonBit 语言编译器。")
  println("每个挑战都包含一个测试文件（.mbt），你需要通过这些测试来验证你的实现。")
  println("准备好了吗？让我们开始吧！")
  println("========================================================")
}

fn print_conguratulation() -> Unit {
  println("\n========================================================")
  println("🎉 所有测试均已通过，恭喜你完成了所有挑战！")
  println("现在，你可以将你的MiniMoonBit项目进行整理，然后提交到正式的评测机器中，以获得最终的认证。")
  println("也可以继续探索MoonBit语言的更多特性，尝试实现更多功能！")
  println("祝你在MiniMoonBit的旅程中一切顺利！")
  println("========================================================")
}
