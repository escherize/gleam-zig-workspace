# Ideas parked for later

## Single-file zig output (2026-08-20)

Question: can a Gleam project compile to ONE .zig file, so anyone with a
zig toolchain can `zig run app.zig` with no gleam installed?

Assessment: not implemented, and nothing blocks it. The generated tree is
textually composable:

- Each generated module already references siblings only through import
  consts (`const M$gleam/io = @import(...)`). Rewriting those to nested
  namespace structs (`const M$gleam$io = struct { ...module body... };`)
  gives the same names with no filesystem imports. Zig namespaces via
  `const X = struct {}` are exactly this.
- The prelude inlines at the top; `@import("std")` and
  `@import("builtin")` are the only external imports left.
- FFI files (gleam_stdlib.zig, simplifile_zig.zig) are self-contained
  except for their prelude import - same struct-wrapping treatment.
- Collisions: generated identifiers are already module-scoped through the
  import consts; wrapping preserves that. Raw identifiers (@"...") keep
  slashes legal in names.

Sketch: `gleam export zig-source --single-file` walks the generated
build directory in dependency order, wraps each module file in
`const <mangled name> = struct { ... };`, rewrites the import-const lines
to reference the wrapped names, drops per-file prelude imports in favour
of one inlined copy, and emits entrypoint code at the bottom. Mostly a
string-processing pass over already-generated output; no codegen changes
required. Estimate: an afternoon, most of it testing.

Payoff: zero-dependency distribution (send one file), trivial embedding
of Gleam code in existing zig projects, and a natural artifact for
playground-style tooling.
