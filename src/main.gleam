import gleam/io
import gleam/list
import internal/scanner.{type Token}

import argv
import simplifile

pub fn main() {
  let args = argv.load().arguments

  case args {
    ["tokenize", filename] -> {
      case simplifile.read(filename) {
        Ok(contents) -> {
          let tokens = scanner.scan_tokens(contents)
          scanner.print_tokens(tokens)
          exit(get_exit_code(tokens))
        }
        Error(error) -> {
          io.println_error("Error: " <> simplifile.describe_error(error))
          exit(1)
        }
      }
    }
    _ -> {
      io.println_error("Usage: ./your_program.sh tokenize <filename>")
      exit(1)
    }
  }
}

fn get_exit_code(tokens: List(Token)) -> Int {
  case tokens |> list.any(scanner.is_unexpected_token) {
    True -> 65
    False -> 0
  }
}

@external(erlang, "erlang", "halt")
pub fn exit(code: Int) -> Nil
