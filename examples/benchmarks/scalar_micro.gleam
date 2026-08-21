import gleam/int
import gleam/io

// Scalar-compute benchmark: naive fib (call-heavy int recursion) plus a
// float loop (mandelbrot-style iteration), the workloads unboxing targets.
pub fn main() {
  io.println(int.to_string(fib(32)))
  io.println(int.to_string(escape_count(0.35, 0.35, 4_000_000)))
}

fn fib(n: Int) -> Int {
  case n < 2 {
    True -> n
    False -> fib(n - 1) + fib(n - 2)
  }
}

fn escape_count(cr: Float, ci: Float, max: Int) -> Int {
  iterate(0.0, 0.0, cr, ci, 0, max)
}

fn iterate(zr: Float, zi: Float, cr: Float, ci: Float, n: Int, max: Int) -> Int {
  case n >= max || zr *. zr +. zi *. zi >. 4.0 {
    True -> n
    False ->
      iterate(zr *. zr -. zi *. zi +. cr, 2.0 *. zr *. zi +. ci, cr, ci, n + 1, max)
  }
}
