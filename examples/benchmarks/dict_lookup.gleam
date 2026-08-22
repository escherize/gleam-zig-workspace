// Dictionary workload: build a map of word -> length from a generated
// word list, then look every key back up and sum. Insert-and-lookup
// heavy, the shape of any real program that indexes data.
//
// Published size: 10_000 words (README). This harness copy uses 500:
// with today's O(n) assoc-list dict, 10_000 inserts is ~100M
// comparisons and blows the Debug leak-checking budget — which is
// exactly what the published number reports.
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string

const count = 500

pub fn main() {
  let words = build_words(count, [])
  let table = index(words, dict.new())
  let total = lookup_all(words, table, 0)
  io.println(int.to_string(dict.size(table)) <> " " <> int.to_string(total))
}

// Deterministic pseudo-words: base-26 rendering of the index, so keys
// are distinct strings of varying length with no I/O dependency.
fn build_words(n: Int, acc: List(String)) -> List(String) {
  case n {
    0 -> acc
    _ -> build_words(n - 1, [word(n, ""), ..acc])
  }
}

fn word(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let letter = case n % 26 {
        0 -> "a"
        1 -> "b"
        2 -> "c"
        3 -> "d"
        4 -> "e"
        5 -> "f"
        6 -> "g"
        7 -> "h"
        8 -> "i"
        9 -> "j"
        10 -> "k"
        11 -> "l"
        12 -> "m"
        13 -> "n"
        14 -> "o"
        15 -> "p"
        16 -> "q"
        17 -> "r"
        18 -> "s"
        19 -> "t"
        20 -> "u"
        21 -> "v"
        22 -> "w"
        23 -> "x"
        24 -> "y"
        _ -> "z"
      }
      word(n / 26, acc <> letter)
    }
  }
}

fn index(words: List(String), table: dict.Dict(String, Int)) -> dict.Dict(String, Int) {
  list.fold(words, table, fn(acc, w) { dict.insert(acc, w, string_length(w)) })
}

fn lookup_all(words: List(String), table: dict.Dict(String, Int), acc: Int) -> Int {
  case words {
    [] -> acc
    [w, ..rest] ->
      case dict.get(table, w) {
        Ok(n) -> lookup_all(rest, table, acc + n)
        Error(_) -> lookup_all(rest, table, acc)
      }
  }
}

fn string_length(s: String) -> Int {
  string.length(s)
}
