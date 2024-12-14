import gleeunit/should
import internal/scanner.{
  Token,
  LeftParen,
  RightParen,
  LeftBrace,
  RightBrace,
  Comma,
  Dot,
  Minus,
  Plus,
  Semicolon,
  Slash,
  Star,
  EndOfFile,
  scan_tokens}
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

pub fn punctuation1_test() {
  scan_tokens("({*.,+*})")
  |> should.equal([
    Token(LeftParen, "(", 0, None),
    Token(LeftBrace, "{", 0, None),
    Token(Star, "*", 0, None),
    Token(Dot, ".", 0, None),
    Token(Comma, ",", 0, None),
    Token(Plus, "+", 0, None),
    Token(Star, "*", 0, None),
    Token(RightBrace, "}", 0, None),
    Token(RightParen, ")", 0, None),
    Token(EndOfFile, "", 0, None),
  ])
}

pub fn punctuation2_test() {
  scan_tokens("-/;")
  |> should.equal([
    Token(Minus, "-", 0, None),
    Token(Slash, "/", 0, None),
    Token(Semicolon, ";", 0, None),
    Token(EndOfFile, "", 0, None),
  ])
}
