# One ray tracer, three targets

`src/raytracer.gleam` is ~200 lines of pure standard-library Gleam:
spheres, a floor, hard shadows, reflections, PPM to stdout. It runs
unchanged on all three compilation targets, and all three produce
byte-identical output (md5 `7a452dda1311ec87af42a1e22ba1367c`):

```sh
gleam run --target erlang     > erl.ppm
gleam run --target javascript > js.ppm
gleam export zig-executable --out raytracer && ./raytracer > native.ppm
```

## Measured (320x240, 3 reflection bounces, Apple M-series)

| Target | Time | Peak RSS | Needs installed | Artifact |
|---|---|---|---|---|
| native (zig, ReleaseFast) | 0.66s | **3.9MB** | nothing | **421KB static binary** |
| javascript (node 22) | **0.12s** | 65MB | node | build tree |
| erlang (OTP 27, via gleam run) | 1.48s | 104MB | OTP | build tree |

Honest read: V8's JIT wins raw compute today — the zig target's uniform
boxed values pay a dup/drop plus a bounds check per field access, and
closing that gap means unboxing, which is future work. The zig target
wins everything else: 17-27x less memory, a single dependency-free
static binary, and `--target-triple x86_64-linux` cross-compiles the
same render for a bare VPS from this same checkout.

This benchmark drove two runtime improvements: streaming stdout writes
(the positional writer overwrote redirected output) and release-mode
object pools for records, cons cells, slices and small strings
(0.72s / 7.4MB -> 0.66s / 3.9MB).
