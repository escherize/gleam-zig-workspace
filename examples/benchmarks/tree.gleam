// Allocation-heavy sum-type workload: build full binary trees, check
// them with a recursive traversal, and sum checks across a range of
// depths (the classic "binary trees" allocation benchmark's shape).
// Exercises multi-constructor custom types: construction, pattern
// matching, and garbage through reference counting.
//
// Published size: depth 21, 4 iterations. Harness copy: depth 12,
// 10 iterations.
import gleam/int
import gleam/io

pub type Tree {
  Leaf
  Node(left: Tree, value: Int, right: Tree)
}

fn make(depth: Int, value: Int) -> Tree {
  case depth <= 0 {
    True -> Node(Leaf, value, Leaf)
    False ->
      Node(
        make(depth - 1, 2 * value),
        value,
        make(depth - 1, 2 * value + 1),
      )
  }
}

fn check(tree: Tree) -> Int {
  case tree {
    Leaf -> 0
    Node(left, value, right) -> value + check(left) + check(right)
  }
}

pub fn main() {
  let total = iterate(12, 10, 0)
  io.println(int.to_string(total))
}

fn iterate(depth: Int, n: Int, acc: Int) -> Int {
  case n <= 0 {
    True -> acc
    False -> {
      let t = make(depth, 1)
      iterate(depth, n - 1, acc + check(t))
    }
  }
}
