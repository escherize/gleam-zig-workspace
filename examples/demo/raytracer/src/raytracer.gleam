//// A small ray tracer in pure standard-library Gleam: spheres, a floor,
//// point light, hard shadows and reflections. Writes a PPM image to
//// stdout. Runs unchanged on the erlang, javascript and zig targets —
//// identical output on all three is the correctness check, and the
//// closure-heavy immutable vector math is exactly the workload Perceus
//// reference counting is built for.

import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string

const width = 320

const height = 240

const max_depth = 3

pub type Vec {
  Vec(x: Float, y: Float, z: Float)
}

pub type Sphere {
  Sphere(center: Vec, radius: Float, color: Vec, reflect: Float)
}

fn add(a: Vec, b: Vec) -> Vec {
  Vec(a.x +. b.x, a.y +. b.y, a.z +. b.z)
}

fn sub(a: Vec, b: Vec) -> Vec {
  Vec(a.x -. b.x, a.y -. b.y, a.z -. b.z)
}

fn scale(a: Vec, s: Float) -> Vec {
  Vec(a.x *. s, a.y *. s, a.z *. s)
}

fn mul(a: Vec, b: Vec) -> Vec {
  Vec(a.x *. b.x, a.y *. b.y, a.z *. b.z)
}

fn dot(a: Vec, b: Vec) -> Float {
  a.x *. b.x +. a.y *. b.y +. a.z *. b.z
}

fn norm(a: Vec) -> Vec {
  let len = float_sqrt(dot(a, a))
  case len >. 0.0 {
    True -> scale(a, 1.0 /. len)
    False -> a
  }
}

fn float_sqrt(x: Float) -> Float {
  case float.square_root(x) {
    Ok(r) -> r
    Error(_) -> 0.0
  }
}

fn scene() -> List(Sphere) {
  [
    Sphere(Vec(0.0, -0.5, 4.0), 1.0, Vec(0.9, 0.2, 0.2), 0.4),
    Sphere(Vec(1.8, 0.0, 5.5), 1.5, Vec(0.2, 0.5, 0.9), 0.5),
    Sphere(Vec(-1.9, 0.2, 5.0), 1.2, Vec(0.2, 0.8, 0.3), 0.3),
    Sphere(Vec(0.3, -1.2, 3.2), 0.5, Vec(0.9, 0.8, 0.2), 0.6),
    // The floor is a huge sphere far below.
    Sphere(Vec(0.0, -10_001.5, 5.0), 10_000.0, Vec(0.7, 0.7, 0.7), 0.1),
  ]
}

const light = Vec(-4.0, 6.0, 0.0)

type Hit {
  Hit(t: Float, sphere: Sphere)
  Miss
}

fn intersect(origin: Vec, dir: Vec, sphere: Sphere) -> Float {
  let oc = sub(origin, sphere.center)
  let b = 2.0 *. dot(oc, dir)
  let c = dot(oc, oc) -. sphere.radius *. sphere.radius
  let disc = b *. b -. 4.0 *. c
  case disc <. 0.0 {
    True -> -1.0
    False -> {
      let sq = float_sqrt(disc)
      let t1 = { 0.0 -. b -. sq } /. 2.0
      case t1 >. 0.001 {
        True -> t1
        False -> {
          let t2 = { 0.0 -. b +. sq } /. 2.0
          case t2 >. 0.001 {
            True -> t2
            False -> -1.0
          }
        }
      }
    }
  }
}

fn closest(origin: Vec, dir: Vec, spheres: List(Sphere)) -> Hit {
  list.fold(spheres, Miss, fn(best, sphere) {
    let t = intersect(origin, dir, sphere)
    case t >. 0.0 {
      False -> best
      True ->
        case best {
          Miss -> Hit(t, sphere)
          Hit(bt, _) ->
            case t <. bt {
              True -> Hit(t, sphere)
              False -> best
            }
        }
    }
  })
}

fn in_shadow(point: Vec, spheres: List(Sphere)) -> Bool {
  let to_light = sub(light, point)
  let dist = float_sqrt(dot(to_light, to_light))
  let dir = norm(to_light)
  case closest(point, dir, spheres) {
    Hit(t, _) -> t <. dist
    Miss -> False
  }
}

fn trace(origin: Vec, dir: Vec, spheres: List(Sphere), depth: Int) -> Vec {
  case closest(origin, dir, spheres) {
    Miss -> {
      // Sky gradient
      let t = { dir.y +. 1.0 } /. 2.0
      add(scale(Vec(1.0, 1.0, 1.0), 1.0 -. t), scale(Vec(0.4, 0.6, 0.9), t))
    }
    Hit(t, sphere) -> {
      let point = add(origin, scale(dir, t))
      let normal = norm(sub(point, sphere.center))
      let to_light = norm(sub(light, point))
      let diffuse = float.max(dot(normal, to_light), 0.0)
      let lit = case in_shadow(point, spheres) {
        True -> 0.1
        False -> 0.1 +. 0.9 *. diffuse
      }
      let base = scale(sphere.color, lit)
      case depth > 0 && sphere.reflect >. 0.0 {
        False -> base
        True -> {
          let refl_dir =
            norm(sub(dir, scale(normal, 2.0 *. dot(dir, normal))))
          let refl = trace(point, refl_dir, spheres, depth - 1)
          add(scale(base, 1.0 -. sphere.reflect), scale(refl, sphere.reflect))
        }
      }
    }
  }
}

fn channel(v: Float) -> String {
  let clamped = float.min(float.max(v, 0.0), 1.0)
  int.to_string(float.round(clamped *. 255.0))
}

fn upto(n: Int) -> List(Int) {
  upto_loop(n - 1, [])
}

fn upto_loop(n: Int, acc: List(Int)) -> List(Int) {
  case n < 0 {
    True -> acc
    False -> upto_loop(n - 1, [n, ..acc])
  }
}

fn render_row(y: Int, spheres: List(Sphere)) -> String {
  let fy = int.to_float(y)
  let fh = int.to_float(height)
  let fw = int.to_float(width)
  upto(width)
  |> list.map(fn(x) {
    let fx = int.to_float(x)
    let u = { 2.0 *. fx -. fw } /. fh
    let v = { fh -. 2.0 *. fy } /. fh
    let dir = norm(Vec(u, v, 2.0))
    let color = trace(Vec(0.0, 0.5, 0.0), dir, spheres, max_depth)
    channel(color.x) <> " " <> channel(color.y) <> " " <> channel(color.z)
  })
  |> string.join(" ")
}

pub fn main() {
  let spheres = scene()
  io.println("P3")
  io.println(int.to_string(width) <> " " <> int.to_string(height))
  io.println("255")
  upto(height)
  |> list.each(fn(y) { io.println(render_row(y, spheres)) })
}
