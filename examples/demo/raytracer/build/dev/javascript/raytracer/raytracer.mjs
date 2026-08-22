import * as $float from "../gleam_stdlib/gleam/float.mjs";
import * as $int from "../gleam_stdlib/gleam/int.mjs";
import * as $io from "../gleam_stdlib/gleam/io.mjs";
import * as $list from "../gleam_stdlib/gleam/list.mjs";
import * as $string from "../gleam_stdlib/gleam/string.mjs";
import {
  Ok,
  toList,
  List$Empty$const as $List$Empty$const,
  prepend as listPrepend,
  CustomType as $CustomType,
  divideFloat,
} from "./gleam.mjs";

export class Vec extends $CustomType {
  constructor(x, y, z) {
    super();
    this.x = x;
    this.y = y;
    this.z = z;
  }
}
export const Vec$Vec = (x, y, z) => new Vec(x, y, z);
export const Vec$isVec = (value) => value instanceof Vec;
export const Vec$Vec$x = (value) => value.x;
export const Vec$Vec$0 = (value) => value.x;
export const Vec$Vec$y = (value) => value.y;
export const Vec$Vec$1 = (value) => value.y;
export const Vec$Vec$z = (value) => value.z;
export const Vec$Vec$2 = (value) => value.z;

export class Sphere extends $CustomType {
  constructor(center, radius, color, reflect) {
    super();
    this.center = center;
    this.radius = radius;
    this.color = color;
    this.reflect = reflect;
  }
}
export const Sphere$Sphere = (center, radius, color, reflect) =>
  new Sphere(center, radius, color, reflect);
export const Sphere$isSphere = (value) => value instanceof Sphere;
export const Sphere$Sphere$center = (value) => value.center;
export const Sphere$Sphere$0 = (value) => value.center;
export const Sphere$Sphere$radius = (value) => value.radius;
export const Sphere$Sphere$1 = (value) => value.radius;
export const Sphere$Sphere$color = (value) => value.color;
export const Sphere$Sphere$2 = (value) => value.color;
export const Sphere$Sphere$reflect = (value) => value.reflect;
export const Sphere$Sphere$3 = (value) => value.reflect;

class Hit extends $CustomType {
  constructor(t, sphere) {
    super();
    this.t = t;
    this.sphere = sphere;
  }
}

class Miss extends $CustomType {}
const Hit$Miss$const = new Miss();

const light = /* @__PURE__ */ new Vec(-4.0, 6.0, 0.0);

const max_depth = 3;

const width = 320;

const height = 240;

function add(a, b) {
  return new Vec(a.x + b.x, a.y + b.y, a.z + b.z);
}

function sub(a, b) {
  return new Vec(a.x - b.x, a.y - b.y, a.z - b.z);
}

function scale(a, s) {
  return new Vec(a.x * s, a.y * s, a.z * s);
}

function dot(a, b) {
  return ((a.x * b.x) + (a.y * b.y)) + (a.z * b.z);
}

function float_sqrt(x) {
  let $ = $float.square_root(x);
  if ($ instanceof Ok) {
    let r = $[0];
    return r;
  } else {
    return 0.0;
  }
}

function norm(a) {
  let len = float_sqrt(dot(a, a));
  let $ = len > 0.0;
  if ($) {
    return scale(a, divideFloat(1.0, len));
  } else {
    return a;
  }
}

function scene() {
  return toList([
    new Sphere(new Vec(0.0, -0.5, 4.0), 1.0, new Vec(0.9, 0.2, 0.2), 0.4),
    new Sphere(new Vec(1.8, 0.0, 5.5), 1.5, new Vec(0.2, 0.5, 0.9), 0.5),
    new Sphere(new Vec(-1.9, 0.2, 5.0), 1.2, new Vec(0.2, 0.8, 0.3), 0.3),
    new Sphere(new Vec(0.3, -1.2, 3.2), 0.5, new Vec(0.9, 0.8, 0.2), 0.6),
    new Sphere(
      new Vec(0.0, -10001.5, 5.0),
      10000.0,
      new Vec(0.7, 0.7, 0.7),
      0.1,
    ),
  ]);
}

function intersect(origin, dir, sphere) {
  let oc = sub(origin, sphere.center);
  let b = 2.0 * dot(oc, dir);
  let c = dot(oc, oc) - (sphere.radius * sphere.radius);
  let disc = (b * b) - (4.0 * c);
  let $ = disc < 0.0;
  if ($) {
    return -1.0;
  } else {
    let sq = float_sqrt(disc);
    let t1 = ((0.0 - b) - sq) / 2.0;
    let $1 = t1 > 0.001;
    if ($1) {
      return t1;
    } else {
      let t2 = ((0.0 - b) + sq) / 2.0;
      let $2 = t2 > 0.001;
      if ($2) {
        return t2;
      } else {
        return -1.0;
      }
    }
  }
}

function closest(origin, dir, spheres) {
  return $list.fold(
    spheres,
    Hit$Miss$const,
    (best, sphere) => {
      let t = intersect(origin, dir, sphere);
      let $ = t > 0.0;
      if ($) {
        if (best instanceof Hit) {
          let bt = best.t;
          let $1 = t < bt;
          if ($1) {
            return new Hit(t, sphere);
          } else {
            return best;
          }
        } else {
          return new Hit(t, sphere);
        }
      } else {
        return best;
      }
    },
  );
}

function in_shadow(point, spheres) {
  let to_light = sub(light, point);
  let dist = float_sqrt(dot(to_light, to_light));
  let dir = norm(to_light);
  let $ = closest(point, dir, spheres);
  if ($ instanceof Hit) {
    let t = $.t;
    return t < dist;
  } else {
    return false;
  }
}

function trace(origin, dir, spheres, depth) {
  let $ = closest(origin, dir, spheres);
  if ($ instanceof Hit) {
    let t = $.t;
    let sphere = $.sphere;
    let point = add(origin, scale(dir, t));
    let normal = norm(sub(point, sphere.center));
    let to_light = norm(sub(light, point));
    let diffuse = $float.max(dot(normal, to_light), 0.0);
    let _block;
    let $1 = in_shadow(point, spheres);
    if ($1) {
      _block = 0.1;
    } else {
      _block = 0.1 + (0.9 * diffuse);
    }
    let lit = _block;
    let base = scale(sphere.color, lit);
    let $2 = (depth > 0) && (sphere.reflect > 0.0);
    if ($2) {
      let refl_dir = norm(sub(dir, scale(normal, 2.0 * dot(dir, normal))));
      let refl = trace(point, refl_dir, spheres, depth - 1);
      return add(scale(base, 1.0 - sphere.reflect), scale(refl, sphere.reflect));
    } else {
      return base;
    }
  } else {
    let t = (dir.y + 1.0) / 2.0;
    return add(
      scale(new Vec(1.0, 1.0, 1.0), 1.0 - t),
      scale(new Vec(0.4, 0.6, 0.9), t),
    );
  }
}

function channel(v) {
  let clamped = $float.min($float.max(v, 0.0), 1.0);
  return $int.to_string($float.round(clamped * 255.0));
}

function upto_loop(loop$n, loop$acc) {
  while (true) {
    let n = loop$n;
    let acc = loop$acc;
    let $ = n < 0;
    if ($) {
      return acc;
    } else {
      loop$n = n - 1;
      loop$acc = listPrepend(n, acc);
    }
  }
}

function upto(n) {
  return upto_loop(n - 1, $List$Empty$const);
}

function render_row(y, spheres) {
  let fy = $int.to_float(y);
  let fh = $int.to_float(height);
  let fw = $int.to_float(width);
  let _pipe = upto(width);
  let _pipe$1 = $list.map(
    _pipe,
    (x) => {
      let fx = $int.to_float(x);
      let u = divideFloat(((2.0 * fx) - fw), fh);
      let v = divideFloat((fh - (2.0 * fy)), fh);
      let dir = norm(new Vec(u, v, 2.0));
      let color = trace(new Vec(0.0, 0.5, 0.0), dir, spheres, max_depth);
      return (((channel(color.x) + " ") + channel(color.y)) + " ") + channel(
        color.z,
      );
    },
  );
  return $string.join(_pipe$1, " ");
}

export function main() {
  let spheres = scene();
  $io.println("P3");
  $io.println(($int.to_string(width) + " ") + $int.to_string(height));
  $io.println("255");
  let _pipe = upto(height);
  return $list.each(
    _pipe,
    (y) => { return $io.println(render_row(y, spheres)); },
  );
}
