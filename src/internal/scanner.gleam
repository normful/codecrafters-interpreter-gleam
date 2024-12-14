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

pub fn scan_tokens(contents: String) -> List(Token) {
  string.to_graphemes(contents)
  |> list.map(grapheme_to_token)
  |> list.append([Token(token_type: EndOfFile, lexeme: "", line: line_number_todo, literal: None)])
}

pub fn print_tokens(tokens: List(Token)) -> Nil {
  tokens |> list.each(fn(token) {
    case token {
      Token(token_type: Unexpected, line: line, lexeme: lexeme, ..) ->  {
        io.println_error("[line " <> int.to_string(line) <> "] Error: Unexpected character: " <> lexeme)
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

const line_number_todo = 1

fn grapheme_to_token(grapheme: String) -> Token {
  case grapheme {
    "(" -> Token(token_type: LeftParen, lexeme: "(", line: line_number_todo, literal: None)
    ")" -> Token(token_type: RightParen, lexeme: ")", line: line_number_todo, literal: None)
    "{" -> Token(token_type: LeftBrace, lexeme: "{", line: line_number_todo, literal: None)
    "}" -> Token(token_type: RightBrace, lexeme: "}", line: line_number_todo, literal: None)
    "," -> Token(token_type: Comma, lexeme: ",", line: line_number_todo, literal: None)
    "." -> Token(token_type: Dot, lexeme: ".", line: line_number_todo, literal: None)
    "-" -> Token(token_type: Minus, lexeme: "-", line: line_number_todo, literal: None)
    "+" -> Token(token_type: Plus, lexeme: "+", line: line_number_todo, literal: None)
    ";" -> Token(token_type: Semicolon, lexeme: ";", line: line_number_todo, literal: None)
    "*" -> Token(token_type: Star, lexeme: "*", line: line_number_todo, literal: None)
    "/" -> Token(token_type: Slash, lexeme: "/", line: line_number_todo, literal: None)
    _ as lexeme -> Token(token_type: Unexpected, lexeme:, line: line_number_todo, literal: None)
  }
}
