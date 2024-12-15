import gleam/option.{type Option, None}
import gleam/list
import gleam/io
import gleam/string
import gleam/int

pub type TokenType {
  LeftParen
  RightParen
  LeftBrace
  RightBrace
  Comma
  Dot
  Minus
  Plus
  Semicolon
  Slash
  Star
  Equal
  EqualEqual
  Bang
  BangEqual
  EndOfFile
  Unexpected
}

fn token_type_to_string(token_type: TokenType) -> String {
  case token_type {
    LeftParen -> "LEFT_PAREN"
    RightParen -> "RIGHT_PAREN"
    LeftBrace -> "LEFT_BRACE"
    RightBrace -> "RIGHT_BRACE"
    Comma -> "COMMA"
    Dot -> "DOT"
    Minus -> "MINUS"
    Plus -> "PLUS"
    Semicolon -> "SEMICOLON"
    Slash -> "SLASH"
    Star -> "STAR"
    Equal -> "EQUAL"
    EqualEqual -> "EQUAL_EQUAL"
    Bang -> "BANG"
    BangEqual -> "BANG_EQUAL"
    EndOfFile -> "EOF"
    Unexpected -> "unexpected token"
  }
}

pub type Literal {
  StringLiteral
  NumberLiteral
}

fn token_literal_to_string(lit: Option(Literal)) -> String {
  case lit {
    None -> "null"
    _ -> "TODO(norman): other token literals as a string"
  }
}

pub type Token {
  Token(token_type: TokenType, lexeme: String, line: Int, literal: Option(Literal))
}

pub fn print_tokens(tokens: List(Token)) -> Nil {
  tokens |> list.each(fn(token) {
    case token {
      Token(token_type: Unexpected, line: line, lexeme: lexeme, ..) -> {
        io.println_error(
        "[line " <> int.to_string(line) <>
          "] Error: Unexpected character: " <> lexeme)
      }
      _ -> {
        io.println(token_type_to_string(token.token_type) <> " " <>
          token.lexeme <> " " <>
          token_literal_to_string(token.literal))
      }
    }
  })
}

pub fn is_unexpected_token(token: Token) -> Bool {
  case token {
    Token(token_type: Unexpected, ..) -> True
    _ -> False
  }
}

fn map_single(grapheme: String, line_num: Int) -> List(Token) {
  let token_type = case grapheme {
    "(" -> LeftParen
    ")" -> RightParen
    "{" -> LeftBrace
    "}" -> RightBrace
    "," -> Comma
    "." -> Dot
    "-" -> Minus
    "+" -> Plus
    ";" -> Semicolon
    "*" -> Star
    "/" -> Slash
    "!" -> Bang
    "=" -> Equal
    _  -> Unexpected
  }
  [Token(
    token_type: token_type,
    lexeme: grapheme,
    line: line_num,
    literal: None,
  )]
}

fn map_double(grapheme_1: String, grapheme_2: String, line_num: Int) -> List(Token) {
  case grapheme_1, grapheme_2 {
    "!", "=" -> [Token(token_type: BangEqual, lexeme: "!=", line: line_num, literal: None)]
    "=", "=" -> [Token(token_type: EqualEqual, lexeme: "==", line: line_num, literal: None)]
    a, b -> list.append(map_single(a, line_num), map_single(b, line_num))
  }
}

pub fn scan_tokens(contents: String) -> List(Token) {
  scan_loop(contents, [], 1)
}

fn scan_loop(rest: String, tokens: List(Token), line_num: Int) -> List(Token) {
  let eof_token = [Token(token_type: EndOfFile, lexeme: "", line: line_num, literal: None)]

  case string.pop_grapheme(rest) {
    Ok(#("!", tail_1)) -> case string.pop_grapheme(tail_1) {
      Ok(#("=", tail_2)) -> scan_loop(
        tail_2,
        tokens |> list.append(map_double("!", "=", line_num)),
        line_num
      )
      Ok(#(_head_2, _tail_2)) -> scan_loop(
        tail_1,
        tokens |> list.append(map_single("!", line_num)),
        line_num
      )
      Error(Nil) -> tokens |> list.append(map_single("!", line_num)) |> list.append(eof_token)
    }
    Ok(#("=", tail_1)) -> case string.pop_grapheme(tail_1) {
      Ok(#("=", tail_2)) -> scan_loop(
        tail_2,
        tokens |> list.append(map_double("=", "=", line_num)),
        line_num
      )
      Ok(#(head_2, tail_2)) -> scan_loop(
        tail_2,
        tokens |> list.append(map_double("=", head_2, line_num)),
        line_num
      )
      Error(Nil) -> tokens |> list.append(map_single("=", line_num)) |> list.append(eof_token)
    }
    Ok(#(head, tail)) -> scan_loop(
      tail,
      tokens |> list.append(map_single(head, line_num)),
      line_num
    )
    Error(Nil) -> tokens |> list.append(eof_token)
  }
}
