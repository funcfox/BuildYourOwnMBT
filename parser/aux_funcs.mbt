///|
typealias @lexer.Token

///|
pub suberror ParseError String derive(Show)

///|
pub(all) enum Either[L, R] {
  Left(L)
  Right(R)
} derive(Show, Eq)
