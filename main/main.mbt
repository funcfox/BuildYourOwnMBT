///|
async fn main {
  let help_info =
    #|Usage: tmbt [options]
    #|
    #|Options:
    #|  -h, --help                Show this help message
    #|  -f, --file <file>         Specify the input TinyMoonbit source file (Must provide)
    #|  -stop-after=lex           Stop after tokenization
    #|  -stop-after=parse         Stop after parsing
    #|  -stop-after=typecheck     Stop after type checking
    #|  -stop-after=knf           Stop after Knf transformation
  let args = @env.args()
  let legal_args = [
    "-h", "--help", "-f", "--file", "-stop-after=parse", "-stop-after=knf",
  ]
  for arg in args[1:] {
    if arg.has_prefix("-") && !legal_args.contains(arg) {
      println("Unknown argument: \{arg}")
      println(help_info)
      return
    }
  }
  if args.contains("-h") || args.contains("--help") {
    println(help_info)
    return
  }
  let fidx = args.search_by(arg => arg is "-f" || arg is "--file")
  let code = match fidx {
    Some(idx) if idx + 1 < args.length() => {
      let filename = args[idx + 1]
      if !@fs.exists(filename) {
        println("Error: File '\{filename}' does not exist.")
        return
      }
      @fs.read_file(filename).text()
    }
    Some(_) => {
      println("Error: No file specified after -f/--file option.")
      return
    }
    None => {
      println(
        "Error: No input file specified. Use -f or --file to specify the source file.",
      )
      println(help_info)
      return
    }
  }
  let tokens = @lexer.tokenize(code)
  if args.contains("-stop-after=lex") {
    println("Tokens:")
    for token in tokens {
      println(token)
    }
    return
  }
  let prog = @parser.parse(tokens)
  if args.contains("-stop-after=parse") {
    println("Parsed AST:")
    println(prog)
    return
  }
  let typecheck_ctx = @typecheck.Context::new()
  let checked_prog = typecheck_ctx.check_program(prog)
  if args.contains("-stop-after=typecheck") {
    println("Type-Checked AST:")
    println(checked_prog)
    return
  }
}
