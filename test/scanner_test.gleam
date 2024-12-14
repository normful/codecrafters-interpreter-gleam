import gleeunit/should
import internal/scanner.{EndOfFile, LeftParen, RightParen, LeftBrace, RightBrace, Token, scan_tokens}
import gleam/option.{None}

pub fn empty_string_test() {
  scan_tokens("")
  |> should.equal([
    Token(EndOfFile, "", 0, None)
  ])
}

pub fn one_left_paren_test() {
  scan_tokens("(")
  |> should.equal([
    Token(LeftParen, "(", 0, None),
    Token(EndOfFile, "", 0, None)
  ])
}

pub fn two_left_parens_test() {
  scan_tokens("((")
  |> should.equal([
    Token(LeftParen, "(", 0, None),
    Token(LeftParen, "(", 0, None),
    Token(EndOfFile, "", 0, None),
  ])
}

pub fn parens_pair_test() {
  scan_tokens("()")
  |> should.equal([
    Token(LeftParen, "(", 0, None),
    Token(RightParen, ")", 0, None),
    Token(EndOfFile, "", 0, None),
  ])
}

pub fn braces_pair_test() {
  scan_tokens("{}")
  |> should.equal([
    Token(LeftBrace, "{", 0, None),
    Token(RightBrace, "}", 0, None),
    Token(EndOfFile, "", 0, None),
  ])
}
