import gleam/option.{None, Some}
import gleam/yielder
import gleeunit/should
import internal/scanner.{
  type Token, AndTok, Bang, BangEqual, ClassTok, Comma, Dot, ElseTok, EndOfFile,
  Equal, EqualEqual, FalseTok, ForTok, FunTok, Greater, GreaterEqual, Identifier,
  IfTok, LeftBrace, LeftParen, Less, LessEqual, Minus, NilTok, Number,
  NumberLiteral, OrTok, Plus, PrintTok, ReturnTok, RightBrace, RightParen,
  Semicolon, Slash, Star, String, StringLiteral, SuperTok, ThisTok, Token,
  TrueTok, Unexpected, UnterminatedString, VarTok, WhileTok, Whitespace,
  extract_number_token, is_alpha_underscore, is_bad_token, scan,
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
    Token(EndOfFile, "", 1, None),
  ])
}

const dummy_line_number = 7

pub fn extract_number_token_1_test() {
  extract_number_token("124abc", dummy_line_number)
  |> should.be_ok
  |> should.equal(#(
    Token(Number, "124", dummy_line_number, Some(NumberLiteral(124.0))),
    "abc",
  ))
}

pub fn number_literal_1_test() {
  scan_test("12", [
    Token(Number, "12", 1, Some(NumberLiteral(12.0))),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn number_literal_2_test() {
  scan_test("0.0", [
    Token(Number, "0.0", 1, Some(NumberLiteral(0.0))),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn number_literal_3_test() {
  scan_test("005125", [
    Token(Number, "005125", 1, Some(NumberLiteral(5125.0))),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn number_literal_4_test() {
  scan_test("0123456789.1234567890", [
    Token(
      Number,
      "0123456789.1234567890",
      1,
      Some(NumberLiteral(123_456_789.123456789)),
    ),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn number_expressions_1_test() {
  scan_test("(44+25)>31", [
    Token(LeftParen, "(", 1, None),
    Token(Number, "44", 1, Some(NumberLiteral(44.0))),
    Token(Plus, "+", 1, None),
    Token(Number, "25", 1, Some(NumberLiteral(25.0))),
    Token(RightParen, ")", 1, None),
    Token(Greater, ">", 1, None),
    Token(Number, "31", 1, Some(NumberLiteral(31.0))),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn is_alpha_underscore_1_test() {
  is_alpha_underscore("A") |> should.be_true
  is_alpha_underscore("z") |> should.be_true
  is_alpha_underscore("a") |> should.be_true
  is_alpha_underscore("_") |> should.be_true
  is_alpha_underscore("0") |> should.be_false
  is_alpha_underscore("1") |> should.be_false
  is_alpha_underscore("'") |> should.be_false
}

pub fn identifier_1_test() {
  scan_test("foo bar _hello", [
    Token(Identifier, "foo", 1, None),
    Token(Whitespace, " ", 1, None),
    Token(Identifier, "bar", 1, None),
    Token(Whitespace, " ", 1, None),
    Token(Identifier, "_hello", 1, None),
    Token(EndOfFile, "", 1, None),
  ])
}

pub fn reserved_word_1_test() {
  scan_test(
    "and class else false for fun if nil or print return super this true var while",
    [
      Token(AndTok, "and", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(ClassTok, "class", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(ElseTok, "else", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(FalseTok, "false", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(ForTok, "for", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(FunTok, "fun", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(IfTok, "if", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(NilTok, "nil", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(OrTok, "or", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(PrintTok, "print", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(ReturnTok, "return", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(SuperTok, "super", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(ThisTok, "this", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(TrueTok, "true", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(VarTok, "var", 1, None),
      Token(Whitespace, " ", 1, None),
      Token(WhileTok, "while", 1, None),
      Token(EndOfFile, "", 1, None),
    ],
  )
}
