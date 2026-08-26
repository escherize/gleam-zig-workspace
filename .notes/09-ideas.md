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

## Record footprint: measure before shrinking (#15, 2026-08-26)

The issue proposed three ways to shrink the record header (name-hash
tag, labels in the tag word, pooling by arity). Counting allocations
first pointed somewhere else entirely.

Instrumenting `makeRecordL` over the tree benchmark:

    total=163830  arity0=81920  arity3=81910

Half of every record allocated carries no payload at all. A full binary
tree has 2^d leaves against 2^d-1 internal nodes, so `Leaf` is not a
side case - it is the majority. Each one cost a 120-byte struct (56 of
it header), one allocator round trip, and one free.

Nullary constructors are constants: every `Leaf` is indistinguishable
from every other, so one immortal static per variant does. That removes
50% of allocations rather than the ~27% of *bytes* a 56->24 byte header
would have saved, and the issue's own measurements say round trips, not
bytes, are what hurts. Depth 21: 114.7 -> 57.2s, 2049 -> 1025MB.

The static's rc starts at `maxInt(usize)/2`, which is what keeps the
ordinary rc paths correct without adding a branch to any of them:
`drop` never sees it reach 0 so never frees it, and `dropReuseRecord`
never sees rc == 1 so FBIP reuse never claims it. Half the range rather
than the maximum, because `dup` still increments and would overflow.
It is a `var`, so it lives in writable `.data` - counting still
happens, it just never reaches a value anyone acts on.

Zig does the per-variant bookkeeping: `nullaryRecord` takes a comptime
name, so each distinct name instantiates its own static. The code
generator needed one line.

Left undone: the header is still 56 bytes for records that *do* carry
fields, and the three original options remain open for them. Worth
re-measuring against a benchmark whose allocations are mostly non-nullary
before picking one - this round is evidence that the intuition about
where the cost sits can be wrong by a factor of two.
