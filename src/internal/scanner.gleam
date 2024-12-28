import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder}

pub type Token {
  Token(
    token_type: TokenType,
    lexeme: String,
    line: Int,
    literal: Option(Literal),
  )
}

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

  Bang
  BangEqual
  Equal
  EqualEqual
  Greater
  GreaterEqual
  Less
  LessEqual

  String
  UnterminatedString
  Number
  Identifier

  AndTok
  ClassTok
  ElseTok
  FalseTok
  FunTok
  ForTok
  IfTok
  NilTok
  OrTok
  PrintTok
  ReturnTok
  SuperTok
  ThisTok
  TrueTok
  VarTok
  WhileTok

  Whitespace

  Unexpected

  EndOfFile
}

fn token_type_to_stdout_string(token_type: TokenType) -> String {
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
    String -> "STRING"
    Number -> "NUMBER"
    Identifier -> "IDENTIFIER"
    AndTok -> "AND"
    ClassTok -> "CLASS"
    ElseTok -> "ELSE"
    FalseTok -> "FALSE"
    FunTok -> "FUN"
    ForTok -> "FOR"
    IfTok -> "IF"
    NilTok -> "NIL"
    OrTok -> "OR"
    PrintTok -> "PRINT"
    ReturnTok -> "RETURN"
    SuperTok -> "SUPER"
    ThisTok -> "THIS"
    TrueTok -> "TRUE"
    VarTok -> "VAR"
    WhileTok -> "WHILE"
    EndOfFile -> "EOF"

    // Tokens not printed to stdout
    Unexpected -> "unexpected token"
    Whitespace -> "whitespace token"
    UnterminatedString -> "unterminated string"
  }
}

pub fn is_bad_token(token: Token) -> Bool {
  case token {
    Token(token_type: Unexpected, ..) -> True
    Token(token_type: UnterminatedString, ..) -> True
    _ -> False
  }
}

pub type Literal {
  StringLiteral(String)
  NumberLiteral(Float)
}

fn token_literal_to_string(lit: Option(Literal)) -> String {
  case lit {
    Some(StringLiteral(text)) -> text
    Some(NumberLiteral(num)) -> float.to_string(num)
    None -> "null"
  }
}

pub fn print_tokens(tokens: Yielder(Token)) -> Nil {
  tokens
  |> yielder.each(fn(token) {
    case token {
      Token(token_type: Unexpected, line: line_num, lexeme: lexeme, ..) -> {
        io.println_error(
          "[line "
          <> int.to_string(line_num)
          <> "] Error: Unexpected character: "
          <> lexeme,
        )
      }
      Token(token_type: Whitespace, ..) -> Nil
      Token(token_type: UnterminatedString, line: line_num, ..) -> {
        io.println_error(
          "[line " <> int.to_string(line_num) <> "] Error: Unterminated string.",
        )
      }
      _ -> {
        io.println(
          token_type_to_stdout_string(token.token_type)
          <> " "
          <> token.lexeme
          <> " "
          <> token_literal_to_string(token.literal),
        )
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
      _ -> Unexpected
    }
    Token(
      token_type: token_type,
      lexeme: grapheme,
      line: line_num,
      literal: None,
    )
  })
}

fn map_double(
  grapheme_1: String,
  grapheme_2: String,
  line_num: Int,
) -> Yielder(Token) {
  case grapheme_1, grapheme_2 {
    "<", "=" ->
      yielder.once(fn() {
        Token(
          token_type: LessEqual,
          lexeme: "<=",
          line: line_num,
          literal: None,
        )
      })
    ">", "=" ->
      yielder.once(fn() {
        Token(
          token_type: GreaterEqual,
          lexeme: ">=",
          line: line_num,
          literal: None,
        )
      })
    "!", "=" ->
      yielder.once(fn() {
        Token(
          token_type: BangEqual,
          lexeme: "!=",
          line: line_num,
          literal: None,
        )
      })
    "=", "=" ->
      yielder.once(fn() {
        Token(
          token_type: EqualEqual,
          lexeme: "==",
          line: line_num,
          literal: None,
        )
      })
    a, b -> yielder.append(map_single(a, line_num), map_single(b, line_num))
  }
}

pub fn scan(contents: String) -> Yielder(Token) {
  let start_line_num = 1
  scan_loop(contents, yielder.empty(), start_line_num)
}

fn scan_loop(
  remaining: String,
  tokens: Yielder(Token),
  line_num: Int,
) -> Yielder(Token) {
  let eof_token =
    yielder.once(fn() {
      Token(token_type: EndOfFile, lexeme: "", line: line_num, literal: None)
    })

  case string.pop_grapheme(remaining) {
    // Either:
    // // Comment
    // /  Slash
    Ok(#("/", tail_1)) ->
      case string.pop_grapheme(tail_1) {
        Ok(#("/", tail_2)) ->
          case string.split_once(tail_2, on: "\n") {
            Ok(#(_comment_text, tail_3)) ->
              scan_loop(tail_3, tokens, line_num + 1)
            Error(Nil) ->
              tokens
              |> yielder.append(eof_token)
          }

        Ok(_) ->
          scan_loop(
            tail_1,
            tokens |> yielder.append(map_single("/", line_num)),
            line_num,
          )

        Error(Nil) ->
          tokens
          |> yielder.append(map_single("/", line_num))
          |> yielder.append(eof_token)
      }

    // Either:
    // != BangEqual
    // !  Bang
    Ok(#("!", tail_1)) ->
      case string.pop_grapheme(tail_1) {
        Ok(#("=", tail_2)) ->
          scan_loop(
            tail_2,
            tokens |> yielder.append(map_double("!", "=", line_num)),
            line_num,
          )
        Ok(_) ->
          scan_loop(
            tail_1,
            tokens |> yielder.append(map_single("!", line_num)),
            line_num,
          )
        Error(Nil) ->
          tokens
          |> yielder.append(map_single("!", line_num))
          |> yielder.append(eof_token)
      }

    // Either:
    // == EqualEqual
    // =  Equal
    Ok(#("=", tail_1)) ->
      case string.pop_grapheme(tail_1) {
        Ok(#("=", tail_2)) ->
          scan_loop(
            tail_2,
            tokens |> yielder.append(map_double("=", "=", line_num)),
            line_num,
          )

        Ok(_) ->
          scan_loop(
            tail_1,
            tokens |> yielder.append(map_single("=", line_num)),
            line_num,
          )

        Error(Nil) ->
          tokens
          |> yielder.append(map_single("=", line_num))
          |> yielder.append(eof_token)
      }

    // Either:
    // == GreaterEqual
    // =  Greater
    Ok(#(">", tail_1)) ->
      case string.pop_grapheme(tail_1) {
        Ok(#("=", tail_2)) ->
          scan_loop(
            tail_2,
            tokens |> yielder.append(map_double(">", "=", line_num)),
            line_num,
          )

        Ok(_) ->
          scan_loop(
            tail_1,
            tokens |> yielder.append(map_single(">", line_num)),
            line_num,
          )

        Error(Nil) ->
          tokens
          |> yielder.append(map_single(">", line_num))
          |> yielder.append(eof_token)
      }

    // Either:
    // == LessEqual
    // =  Equal
    Ok(#("<", tail_1)) ->
      case string.pop_grapheme(tail_1) {
        Ok(#("=", tail_2)) ->
          scan_loop(
            tail_2,
            tokens |> yielder.append(map_double("<", "=", line_num)),
            line_num,
          )

        Ok(_) ->
          scan_loop(
            tail_1,
            tokens |> yielder.append(map_single("<", line_num)),
            line_num,
          )

        Error(Nil) ->
          tokens
          |> yielder.append(map_single("<", line_num))
          |> yielder.append(eof_token)
      }

    // Either:
    // String
    // UnterminatedString
    Ok(#("\"", tail_1)) ->
      case string.split_once(tail_1, on: "\"") {
        Ok(#(text_between_quotes, tail_2)) -> {
          scan_loop(
            tail_2,
            tokens
              |> yielder.append(
                yielder.from_list([
                  Token(
                    String,
                    "\"" <> text_between_quotes <> "\"",
                    line_num,
                    Some(StringLiteral(text_between_quotes)),
                  ),
                ]),
              ),
            line_num + newline_char_count(text_between_quotes),
          )
        }
        Error(Nil) ->
          tokens
          |> yielder.append(
            yielder.from_list([
              Token(UnterminatedString, tail_1, line_num, None),
            ]),
          )
          |> yielder.append(eof_token)
      }

    // Newline character
    Ok(#("\n", tail_1)) ->
      scan_loop(
        tail_1,
        tokens |> yielder.append(map_single("\n", line_num)),
        line_num + 1,
      )

    // All other single characters
    Ok(#(head_1, tail_1)) ->
      case is_digit(head_1) {
        True -> {
          case extract_number_token(head_1 <> tail_1, line_num) {
            Ok(#(number_token, tail_2)) ->
              scan_loop(
                tail_2,
                tokens |> yielder.append(yielder.once(fn() { number_token })),
                line_num,
              )
            Error(Nil) -> scan_loop(tail_1, tokens, line_num)
          }
        }

        False ->
          case is_alpha_underscore(head_1) {
            True ->
              case
                extract_identifier_or_reserved_word(head_1 <> tail_1, line_num)
              {
                Ok(#(extracted_token, tail_2)) ->
                  scan_loop(
                    tail_2,
                    tokens
                      |> yielder.append(yielder.once(fn() { extracted_token })),
                    line_num,
                  )
                Error(Nil) -> scan_loop(tail_1, tokens, line_num)
              }

            False ->
              scan_loop(
                tail_1,
                tokens |> yielder.append(map_single(head_1, line_num)),
                line_num,
              )
          }
      }

    // No more graphemes to scan
    Error(Nil) -> tokens |> yielder.append(eof_token)
  }
}

fn newline_char_count(text: String) -> Int {
  string.to_graphemes(text) |> list.count(fn(g) { g == "\n" })
}

pub fn extract_number_token(
  text: String,
  line_num: Int,
) -> Result(#(Token, String), Nil) {
  let #(number_string, rest) = split_number_string_from_rest(text)

  let number_float = case int.parse(number_string), float.parse(number_string) {
    Ok(i), Error(Nil) -> Ok(int.to_float(i))
    Error(Nil), Ok(f) -> Ok(f)
    _, _ -> Error(Nil)
  }

  number_float
  |> result.map(fn(num_float) {
    #(
      Token(
        token_type: Number,
        lexeme: number_string,
        line: line_num,
        literal: Some(NumberLiteral(num_float)),
      ),
      rest,
    )
  })
}

fn split_number_string_from_rest(text: String) -> #(String, String) {
  split_num_loop(text, False, "")
}

fn split_num_loop(
  remaining: String,
  saw_dot: Bool,
  num_accum: String,
) -> #(String, String) {
  case string.pop_grapheme(remaining) {
    Ok(#(head, tail)) ->
      case saw_dot, is_digit(head), is_dot(head) {
        False, True, False -> split_num_loop(tail, False, num_accum <> head)
        False, False, True | True, True, False ->
          split_num_loop(tail, True, num_accum <> head)
        _, _, _ -> #(num_accum, remaining)
      }
    Error(Nil) -> #(num_accum, "")
  }
}

fn is_digit(grapheme: String) -> Bool {
  let assert Ok(re) = regexp.from_string("^[0-9]")
  regexp.check(with: re, content: grapheme)
}

pub fn is_alpha_underscore(grapheme: String) -> Bool {
  let assert Ok(re) = regexp.from_string("^[A-Za-z_]")
  regexp.check(with: re, content: grapheme)
}

pub fn is_alpha_underscore_digit(grapheme: String) -> Bool {
  let assert Ok(re) = regexp.from_string("^[A-Za-z0-9_]")
  regexp.check(with: re, content: grapheme)
}

fn is_dot(grapheme: String) -> Bool {
  grapheme == "."
}

pub fn extract_identifier_or_reserved_word(
  text: String,
  line_num: Int,
) -> Result(#(Token, String), Nil) {
  let #(identifier, rest) = split_identifier_from_rest(text)

  Ok(#(
    Token(
      token_type: Identifier,
      lexeme: identifier,
      line: line_num,
      literal: None,
    ),
    rest,
  ))
}

fn split_identifier_from_rest(text: String) -> #(String, String) {
  split_identifier_loop(text, "")
}

fn split_identifier_loop(
  remaining: String,
  id_accum: String,
) -> #(String, String) {
  case string.pop_grapheme(remaining) {
    Ok(#(head, tail)) ->
      case is_alpha_underscore_digit(head) {
        True -> split_identifier_loop(tail, id_accum <> head)
        False -> #(id_accum, remaining)
      }
    Error(Nil) -> #(id_accum, "")
  }
}
