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
  Equal,
  EqualEqual,
  Bang,
  BangEqual,
  EndOfFile,
  Unexpected,
  scan_tokens,
  is_unexpected_token,
}
import gleam/option.{None}

pub fn empty_string_test() {
  scan_tokens("")
  |> should.equal([
    Token(EndOfFile, "", 1, None)
  ])
}

pub fn one_left_paren_test() {
  scan_tokens("(")
  |> should.equal([
    Token(LeftParen, "(", 1, None),
    Token(EndOfFile, "", 1, None)
  ])
}

pub fn two_left_parens_test() {
  scan_tokens("((")
  |> should.equal([
    Token(LeftParen, "(", 1, None),
    Token(LeftParen, "(", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn parens_pair_test() {
  scan_tokens("()")
  |> should.equal([
    Token(LeftParen, "(", 1, None),
    Token(RightParen, ")", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn braces_pair_test() {
  scan_tokens("{}")
  |> should.equal([
    Token(LeftBrace, "{", 1, None),
    Token(RightBrace, "}", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn punctuation1_test() {
  scan_tokens("({*.,+*})")
  |> should.equal([
    Token(LeftParen, "(", 1, None),
    Token(LeftBrace, "{", 1, None),
    Token(Star, "*", 1, None),
    Token(Dot, ".", 1, None),
    Token(Comma, ",", 1, None),
    Token(Plus, "+", 1, None),
    Token(Star, "*", 1, None),
    Token(RightBrace, "}", 1, None),
    Token(RightParen, ")", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn punctuation2_test() {
  scan_tokens("-/;")
  |> should.equal([
    Token(Minus, "-", 1, None),
    Token(Slash, "/", 1, None),
    Token(Semicolon, ";", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn unexpected_lexeme_test() {
  scan_tokens("@")
  |> should.equal([
    Token(Unexpected, "@", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn is_unexpected_token_test() {
  is_unexpected_token(Token(Unexpected, "@", 1, None)) |> should.be_true
  is_unexpected_token(Token(EndOfFile, "", 1, None)) |> should.be_false
}

pub fn equal_equal_test() {
  scan_tokens("==")
  |> should.equal([
    Token(EqualEqual, "==", 1, None),
    Token(EndOfFile, "", 1, None)
  ])
}

pub fn equal_equal_equal_test() {
  scan_tokens("===")
  |> should.equal([
    Token(EqualEqual, "==", 1, None),
    Token(Equal, "=", 1, None),
    Token(EndOfFile, "", 1, None)
  ])
}

pub fn equal_equal_equal_equal_test() {
  scan_tokens("====")
  |> should.equal([
    Token(EqualEqual, "==", 1, None),
    Token(EqualEqual, "==", 1, None),
    Token(EndOfFile, "", 1, None)
  ])
}

pub fn unexpected_with_equal_equal_test() {
  scan_tokens("((%@$==#))")
  |> should.equal([
    Token(LeftParen, "(", 1, None),
    Token(LeftParen, "(", 1, None),
    Token(Unexpected, "%", 1, None),
    Token(Unexpected, "@", 1, None),
    Token(Unexpected, "$", 1, None),
    Token(EqualEqual, "==", 1, None),
    Token(Unexpected, "#", 1, None),
    Token(RightParen, ")", 1, None),
    Token(RightParen, ")", 1, None),
    Token(EndOfFile, "", 1, None)
  ])
}

pub fn negation_and_equality_test() {
  scan_tokens("!!===")
  |> should.equal([
    Token(Bang, "!", 1, None),
    Token(BangEqual, "!=", 1, None),
    Token(EqualEqual, "==", 1, None),
    Token(EndOfFile, "", 1, None)
  ])
}
