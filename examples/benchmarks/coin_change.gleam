import gleam/int
import gleam/io

// Coin changing, the classic naive recursion: how many ways to make
// `amount` from `coins` (unlimited supply). Exponential on purpose —
// a pure recursion + list-matching + integer benchmark.
fn ways(amount: Int, coins: List(Int)) -> Int {
  case coins {
    _ if amount == 0 -> 1
    _ if amount < 0 -> 0
    [] -> 0
    [c, ..rest] -> ways(amount - c, coins) + ways(amount, rest)
  }
}

pub fn main() {
  io.println(int.to_string(ways(900, [1, 5, 10, 25, 50])))
}
