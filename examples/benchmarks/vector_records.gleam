// Harness copy: 1M iterations so the Debug leak-checking allocator can
// finish. The published benchmark uses 10_000_000 — see README.md.
import gleam/float
import gleam/int
import gleam/io

// Vec-math microbenchmark: the ray tracer's hot shape isolated.
// 10M iterations of add/scale/dot on records.
pub type Vec {
  Vec(x: Float, y: Float, z: Float)
}

fn add(a: Vec, b: Vec) -> Vec {
  Vec(a.x +. b.x, a.y +. b.y, a.z +. b.z)
}

fn scale(a: Vec, s: Float) -> Vec {
  Vec(a.x *. s, a.y *. s, a.z *. s)
}

fn dot(a: Vec, b: Vec) -> Float {
  a.x *. b.x +. a.y *. b.y +. a.z *. b.z
}

fn loop(n: Int, v: Vec, acc: Float) -> Float {
  case n {
    0 -> acc
    _ -> {
      let w = add(v, scale(v, 0.5))
      loop(n - 1, v, acc +. dot(w, w) *. 0.000001)
    }
  }
}

pub fn main() {
  io.println(int.to_string(float.round(loop(1_000_000, Vec(0.1, 0.2, 0.3), 0.0))))
}
