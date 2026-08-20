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

## Branch-aware last-use dataflow (design sketch, 2026-08-20)

The conservative move optimisation handles single straight-line uses.
Full Perceus precision needs per-branch liveness:

- Walk each function body BACKWARD with a live-variable set, mirroring
  emission order exactly (argument order, subject-before-clauses, steps
  before finally).
- At a Var occurrence: if the name is in the live set, this use dups; if
  not, it moves, and the name joins the live set.
- At a case: process each clause with the same live-out; a binding
  consumed in one clause but live-out of another gets a compensation
  drop at the top of the non-consuming clause.
- The result is a set of move-approved occurrence spans (SrcSpan keys)
  plus per-clause compensation lists, consumed by the emitter.
- Verification: differential corpus run against the conservative
  version (outputs + leak gate), plus targeted double-free tests -
  DebugAllocator catches double frees with traces.

Risk concentrates in mirroring emission order; any divergence is a
use-after-free. Build the analysis as a shadow of the emitter walk, not
a separate traversal.

## Stdlib quality ceilings (standing)

Marked `ponytail:` at their implementation sites, ordered by likely
first complaint:
1. Dict is an insertion-ordered assoc list - O(n) per op. A real
   persistent map (HAMT) is the fix; consider porting the JS dict.mjs
   structure.
2. lowercase/uppercase/trim are ASCII; graphemes segment by codepoint.
   Needs Unicode tables (casing + UAX#29); zig std has neither.
3. float.to_string uses zig's {d} formatting - matches JS closely but
   unverified against erlang's shortest-round-trip behaviour.
