import gleam/option.{type Option, None}
import gleam/io
import gleam/string
import gleam/int
import gleam/yielder.{type Yielder}

pub type Token {
  Token(token_type: TokenType, lexeme: String, line: Int, literal: Option(Literal))
}

pub type TokenType {
  LeftParen RightParen LeftBrace RightBrace
  Comma Dot Minus Plus Semicolon Slash Star

  Bang BangEqual
  Equal EqualEqual
  Greater GreaterEqual
  Less LessEqual

  String
  UnterminatedString

  Whitespace

  Unexpected

  EndOfFile
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
    Star -> "STAR"
    Equal -> "EQUAL"
    EqualEqual -> "EQUAL_EQUAL"
    Bang -> "BANG"
    BangEqual -> "BANG_EQUAL"
    Less -> "LESS"
    LessEqual -> "LESS_EQUAL"
    Greater -> "GREATER"
    GreaterEqual -> "GREATER_EQUAL"
    Slash -> "SLASH"
    EndOfFile -> "EOF"

    // Tokens not printed to stdout
    Unexpected -> "unexpected token"
    Whitespace -> "whitespace token"
  }
}

pub fn is_unexpected_token(token: Token) -> Bool {
  case token {
    Token(token_type: Unexpected, ..) -> True
    _ -> False
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

pub fn print_tokens(tokens: Yielder(Token)) -> Nil {
  tokens |> yielder.each(fn(token) {
    case token {
      Token(token_type: Unexpected, line: line_num, lexeme: lexeme, ..) -> {
        io.println_error(
        "[line " <> int.to_string(line_num) <>
          "] Error: Unexpected character: " <> lexeme)
      }
      Token(token_type: Whitespace, ..) -> Nil
      _ -> {
        io.println(token_type_to_string(token.token_type) <> " " <>
          token.lexeme <> " " <>
          token_literal_to_string(token.literal))
      }
    }
  })
}

fn map_single(grapheme: String, line_num: Int) -> Yielder(Token) {
  yielder.once(fn() {
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
      "<" -> Less
      ">" -> Greater
      "!" -> Bang
      "=" -> Equal
      "/" -> Slash
      " " | "\t" | "\n" | "\r" -> Whitespace
      _  -> Unexpected
    }
    Token(token_type: token_type, lexeme: grapheme, line: line_num, literal: None)
  })
}

fn map_double(grapheme_1: String, grapheme_2: String, line_num: Int) -> Yielder(Token) {
  case grapheme_1, grapheme_2 {
    "<", "=" -> yielder.once(fn() { Token(token_type: LessEqual, lexeme: "<=", line: line_num, literal: None) })
    ">", "=" -> yielder.once(fn() { Token(token_type: GreaterEqual, lexeme: ">=", line: line_num, literal: None) })
    "!", "=" -> yielder.once(fn() { Token(token_type: BangEqual, lexeme: "!=", line: line_num, literal: None) })
    "=", "=" -> yielder.once(fn() { Token(token_type: EqualEqual, lexeme: "==", line: line_num, literal: None) })
    a, b -> yielder.append(map_single(a, line_num), map_single(b, line_num))
  }
}

pub fn scan(contents: String) -> Yielder(Token) {
  let start_line_num = 1
  scan_loop(contents, yielder.empty(), start_line_num)
}

fn scan_loop(remaining: String, tokens: Yielder(Token), line_num: Int) -> Yielder(Token) {
  let eof_token = yielder.once(fn() {
    Token(token_type: EndOfFile, lexeme: "", line: line_num, literal: None)
  })

  case string.pop_grapheme(remaining) {

    // Either:
    // // Comment
    // /  Slash
    Ok(#("/", tail_1)) -> case string.pop_grapheme(tail_1) {

      Ok(#("/", tail_2)) -> case string.split_once(tail_2, on: "\n") {
        Ok(#(_comment_text, tail_3)) -> scan_loop(
          tail_3,
          tokens,
          line_num + 1,
        )
        Error(Nil) -> tokens
          |> yielder.append(eof_token)
      }

      Ok(_) -> scan_loop(
        tail_1,
        tokens |> yielder.append(map_single("/", line_num)),
        line_num,
      )

      Error(Nil) -> tokens
        |> yielder.append(map_single("/", line_num))
        |> yielder.append(eof_token)
    }

    // Either:
    // != BangEqual
    // !  Bang
    Ok(#("!", tail_1)) -> case string.pop_grapheme(tail_1) {
      Ok(#("=", tail_2)) -> scan_loop(
        tail_2,
        tokens |> yielder.append(map_double("!", "=", line_num)),
        line_num,
      )
      Ok(_) -> scan_loop(
        tail_1,
        tokens |> yielder.append(map_single("!", line_num)),
        line_num,
      )
      Error(Nil) -> tokens
        |> yielder.append(map_single("!", line_num))
        |> yielder.append(eof_token)
    }

    // Either:
    // == EqualEqual
    // =  Equal
    Ok(#("=", tail_1)) -> case string.pop_grapheme(tail_1) {

      Ok(#("=", tail_2)) -> scan_loop(
        tail_2,
        tokens |> yielder.append(map_double("=", "=", line_num)),
        line_num,
      )

      Ok(_) -> scan_loop(
        tail_1,
        tokens |> yielder.append(map_single("=", line_num)),
        line_num,
      )

      Error(Nil) -> tokens
        |> yielder.append(map_single("=", line_num))
        |> yielder.append(eof_token)
    }

    // Either:
    // == GreaterEqual
    // =  Greater
    Ok(#(">", tail_1)) -> case string.pop_grapheme(tail_1) {

      Ok(#("=", tail_2)) -> scan_loop(
        tail_2,
        tokens |> yielder.append(map_double(">", "=", line_num)),
        line_num,
      )

      Ok(_) -> scan_loop(
        tail_1,
        tokens |> yielder.append(map_single(">", line_num)),
        line_num,
      )

      Error(Nil) -> tokens
        |> yielder.append(map_single(">", line_num))
        |> yielder.append(eof_token)
    }

    // Either:
    // == LessEqual
    // =  Equal
    Ok(#("<", tail_1)) -> case string.pop_grapheme(tail_1) {

      Ok(#("=", tail_2)) -> scan_loop(
        tail_2,
        tokens |> yielder.append(map_double("<", "=", line_num)),
        line_num,
      )

      Ok(_) -> scan_loop(
        tail_1,
        tokens |> yielder.append(map_single("<", line_num)),
        line_num,
      )

      Error(Nil) -> tokens
        |> yielder.append(map_single("<", line_num))
        |> yielder.append(eof_token)
    }
    Ok(#("\n", tail_1)) -> scan_loop(
      tail_1,
      tokens |> yielder.append(map_single("\n", line_num)),
      line_num + 1,
    )

    // All other single characters
    Ok(#(head_1, tail_1)) -> scan_loop(
      tail_1,
      tokens |> yielder.append(map_single(head_1, line_num)),
      line_num,
    )

    // No more graphemes to scan
    Error(Nil) -> tokens |> yielder.append(eof_token)
  }
}
