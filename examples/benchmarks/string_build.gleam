import gleam/int
import gleam/io
import gleam/list
import gleam/string

// Fold-accumulate: acc has a single straight-line use in the lambda, so
// it moves and the append is in place.
pub fn main() {
  let parts = list.map(int_range(1, 200_000, []), int.to_string)
  let joined = list.fold(parts, "", fn(acc, x) { acc <> x <> ";" })
  io.println(int.to_string(string.length(joined)))
}

fn int_range(from: Int, to: Int, acc: List(Int)) -> List(Int) {
  case to < from {
    True -> acc
    False -> int_range(from, to - 1, [to, ..acc])
  }
}
