import gleam/int
import gleam/io
import gleam/list

// List-churn benchmark: builds, maps, filters and folds lists repeatedly.
// The workload Perceus RC is supposed to make cheap.
pub fn main() {
  let total = rounds(200, 0)
  io.println(int.to_string(total))
}

fn rounds(n: Int, acc: Int) -> Int {
  case n {
    0 -> acc
    _ -> rounds(n - 1, acc + round())
  }
}

fn round() -> Int {
  range(5000, [])
  |> list.map(fn(x) { x * 2 })
  |> list.filter(fn(x) { x % 3 == 0 })
  |> list.fold(0, fn(a, b) { a + b })
}

fn range(n: Int, acc: List(Int)) -> List(Int) {
  case n {
    0 -> acc
    _ -> range(n - 1, [n, ..acc])
  }
}
