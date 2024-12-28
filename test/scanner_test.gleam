import gleam/option.{None, Some}
import gleam/result
import gleam/yielder
import gleeunit/should
import internal/scanner.{
  type Token, Bang, BangEqual, Comma, Dot, EndOfFile, Equal, EqualEqual, Greater,
  GreaterEqual, LeftBrace, LeftParen, Less, LessEqual, Minus, Number,
  NumberLiteral, Plus, RightBrace, RightParen, Semicolon, Slash, Star, String,
  StringLiteral, Token, Unexpected, UnterminatedString, Whitespace,
  extract_number_token, is_bad_token, scan,
}

fn scan_test(lox_file_contents: String, expected: List(Token)) -> Nil {
  scan(lox_file_contents)
  |> yielder.to_list
  |> should.equal(expected)
}

pub fn is_bad_token_test() {
  is_bad_token(Token(Unexpected, "@", 1, None)) |> should.be_true
  is_bad_token(Token(UnterminatedString, "foo", 1, None)) |> should.be_true
  is_bad_token(Token(EndOfFile, "", 1, None)) |> should.be_false
}

pub fn unexpected_lexeme_test() {
  scan_test("@", [
    Token(Unexpected, "@", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn empty_string_test() {
  scan_test("", [Token(EndOfFile, "", 1, None)])
}

pub fn one_left_paren_test() {
  scan_test("(", [Token(LeftParen, "(", 1, None), Token(EndOfFile, "", 1, None)])
}

pub fn two_left_parens_test() {
  scan_test("((", [
    Token(LeftParen, "(", 1, None),
    Token(LeftParen, "(", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn parens_pair_test() {
  scan_test("()", [
    Token(LeftParen, "(", 1, None),
    Token(RightParen, ")", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn braces_pair_test() {
  scan_test("{}", [
    Token(LeftBrace, "{", 1, None),
    Token(RightBrace, "}", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn punctuation1_test() {
  scan_test("({*.,+*})", [
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
  scan_test("-/;", [
    Token(Minus, "-", 1, None),
    Token(Slash, "/", 1, None),
    Token(Semicolon, ";", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn equal_equal_test() {
  scan_test("==", [
    Token(EqualEqual, "==", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn equal_equal_equal_test() {
  scan_test("===", [
    Token(EqualEqual, "==", 1, None),
    Token(Equal, "=", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn equal_equal_equal_equal_test() {
  scan_test("====", [
    Token(EqualEqual, "==", 1, None),
    Token(EqualEqual, "==", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn unexpected_with_equal_equal_test() {
  scan_test("((%@$==#))", [
    Token(LeftParen, "(", 1, None),
    Token(LeftParen, "(", 1, None),
    Token(Unexpected, "%", 1, None),
    Token(Unexpected, "@", 1, None),
    Token(Unexpected, "$", 1, None),
    Token(EqualEqual, "==", 1, None),
    Token(Unexpected, "#", 1, None),
    Token(RightParen, ")", 1, None),
    Token(RightParen, ")", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn negation_and_equality_test() {
  scan_test("!!===", [
    Token(Bang, "!", 1, None),
    Token(BangEqual, "!=", 1, None),
    Token(EqualEqual, "==", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn lte_gte_test() {
  scan_test("<<=>>=", [
    Token(Less, "<", 1, None),
    Token(LessEqual, "<=", 1, None),
    Token(Greater, ">", 1, None),
    Token(GreaterEqual, ">=", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn comment_test() {
  scan_test("()// Comment", [
    Token(LeftParen, "(", 1, None),
    Token(RightParen, ")", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn slash_test() {
  scan_test("/()", [
    Token(Slash, "/", 1, None),
    Token(LeftParen, "(", 1, None),
    Token(RightParen, ")", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn tab_newline_space_test() {
  scan_test("(\r\t\n )", [
    Token(LeftParen, "(", 1, None),
    Token(Whitespace, "\r", 1, None),
    Token(Whitespace, "\t", 1, None),
    Token(Whitespace, "\n", 1, None),
    Token(Whitespace, " ", 2, None),
    Token(RightParen, ")", 2, None),
    Token(EndOfFile, "", 2, None),
  ])
}

pub fn multiline_lexical_errors_test() {
  scan_test("#\n@", [
    Token(Unexpected, "#", 1, None),
    Token(Whitespace, "\n", 1, None),
    Token(Unexpected, "@", 2, None),
    Token(EndOfFile, "", 2, None),
  ])
}

pub fn valid_string_literal_test() {
  scan_test("\"ab cd\"", [
    Token(String, "\"ab cd\"", 1, Some(StringLiteral("ab cd"))),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn valid_two_line_string_literal_test() {
  scan_test("\"ab\ncd\"", [
    Token(String, "\"ab\ncd\"", 1, Some(StringLiteral("ab\ncd"))),
    Token(EndOfFile, "", 2, None),
  ])
}

pub fn valid_three_line_string_literal_test() {
  scan_test("\"a b\nc \n d\"", [
    Token(String, "\"a b\nc \n d\"", 1, Some(StringLiteral("a b\nc \n d"))),
    Token(EndOfFile, "", 3, None),
  ])
}

pub fn unterminated_string_literal_test() {
  scan_test("\"ab", [
    Token(UnterminatedString, "ab", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn valid_and_unterminated_string_test() {
  scan_test("\"hello\" \"unterminated", [
    Token(String, "\"hello\"", 1, Some(StringLiteral("hello"))),
    Token(Whitespace, " ", 1, None),
    Token(UnterminatedString, "unterminated", 1, None),
    Token(EndOfFile, "", 1, None)
  ])
}
