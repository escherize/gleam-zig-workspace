import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  io.println("Hello, Joe!")
  io.println(int.to_string(42))
  io.println(string.uppercase("shout"))
  io.println(string.concat(["a", "b", "c"]))
  let doubled = list.map([1, 2, 3], fn(x) { x * 2 })
  io.println(string.inspect(doubled))
  io.println(string.join(["x", "y", "z"], with: "-"))
}
