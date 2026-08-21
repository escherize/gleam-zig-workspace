# Status log

## 2026-08-19: tour passes on zig

Branches: `gleam/` fork branch `zig-target`, `gleam-stdlib/` clone branch
`zig-target` (path-dependency stdlib with zig FFI). Toolchain: zig 0.16.0
vendored at `toolchain/` (checksum-verified). Runner finds zig via
`$GLEAM_ZIG`, falling back to PATH.

### What works

- `gleam build|run --target zig` end to end. `gleam.toml` `target = "zig"`.
- Core language: custom types (with field labels in echo/inspect), tuples,
  lists, closures with captures, fn/constructor references, case with
  guards/alternatives/string prefixes/nested patterns, let assert, assert,
  record updates, pipes (incl. bare `|> echo`), module constants,
  self-tail-call loops (verified 1M iterations), cross-module and
  cross-package calls.
- `@external(zig, "path.zig", "fn")` with forwarding codegen; `.zig` files
  copied as native files; `@target(zig)` gating.
- Stdlib on zig: io, int, float, string, string_tree, dict (assoc-list),
  list/result/option/bool/order/pair/set (pure). Known ceilings marked
  `ponytail:` in `gleam-stdlib/src/gleam_stdlib.zig` (codepoint-based
  "graphemes", ASCII case/trim, O(n) dict).
- Language tour: 60/63 pass vs JS-target baseline via `examples/harness.py`
  (2 lessons lack main, 1 is bit arrays).
- Rosetta corpus (86 programs cached in `examples/rosetta/`): 61 pass,
  0 fail. Skips: 16 missing hex deps (simplifile, gleam/format, input),
  8 no main fn, 1 int-overflow-semantics divergence (Wilson's theorem:
  i64 wraps, JS f64 loses precision, only Erlang bignums are exact).

## 2026-08-20 (later): bit arrays, file I/O, native binaries

- Bit arrays (byte-aligned): shared-buffer RC representation, builder
  construction, matcher-based patterns with dependent sizes; stdlib
  bit_array module FFI (slice, base64/16, is_utf8...). Corpus unskipped.
- simplifile fork (github.com/escherize/gleam-zig-simplifile): read,
  write, append, delete (Enoent-correct), dirs, copy, rename, touch.
  The Find-words rosetta programs run against unixdict.txt.
- `gleam export zig-executable`: ReleaseFast standalone binary; prelude
  picks allocator by builtin.mode (leak gate only in Debug).
- Gate: 129 passed, 0 failed, 20 skipped. Parked idea: single-file zig
  output (.notes/09-ideas.md).

### Known gaps

- Non-byte-aligned bit array segments; utf16/utf32 segments.
- Anonymous fn TCO, mutual recursion: stack-bound (JS parity).
- `float.to_precision`, string trim are ASCII; graphemes are codepoints.
- Panic message format differs from other targets (fine for now).
- Memory: Perceus RC stages 1+2 DONE (2026-08-20). Naive counting
  (dup-at-use, drop-at-scope-exit, consuming helpers, FFI
  borrowed-in/owned-out) plus conservative last-use moves (single
  straight-line use transfers the reference; pipelines are pure moves).
  Gate: full corpus leak-clean under std.heap.DebugAllocator — the
  generated entrypoint drops main's result and exits 2 on any live
  allocation. Benchmark (list churn): peak RSS 236.7MB leaking -> 2.3MB.
  Stage 3 (2026-08-20): FBIP cons reuse — `[x, ..rest] -> [y, ..zs]`
  clauses steal the matched cell when unshared (dropReuseCons/consReuse);
  parameter last-use moves (function, TCO and lambda params) arm it by
  keeping case subjects at rc==1. Benchmark: 1M in-place reuses, cons
  allocations -27%, 0.12s / 2.0MB vs leak-everything 0.08s / 236.7MB.
  Remaining Perceus (optimizations, not correctness): branch-aware
  last-use dataflow, drop specialization, record/tuple reuse, borrowing
  inference. Strings always copy (literals and slices); buffer sharing
  is future work.
- JS-target echo prints floats like `2` for `2.0`; zig prints `2.0`
  (matches Erlang). Harness normalises this.

### Verification

- `examples/harness.py <dirs-or-files>`: runs each program on zig +
  javascript targets, normalised diff. Nondeterministic (random/dict-order)
  programs are exit-code-only.
- Compiler suite: 6180 tests green.

## 2026-08-20 (night): QA sweep, gleam_native, cross-compilation, benchmark

- 10-agent adversarial fan-out audit: 29 confirmed findings (4 critical),
  all fixed. Criticals: guard operands double-freed (borrowed refs fed to
  consuming helpers), bit array int segments >64 bits smashed a fixed
  buffer, >16-segment patterns overran matcher slots, gleam_native
  handles were use-after-free on double close (now alive-flagged boxes
  that panic cleanly). Also: P.stringValue never existed (string module
  constants could not compile), reuse-token escape into conditional
  branches (barrier-contained now), harness classification holes.
- gleam_native (github.com/escherize/gleam-zig-native): OS threads with
  deep-copied closures, sleep, monotonic time, blocking TCP. Echo server
  gate met. argv + envoy forks published.
- Cross-compilation: --target-triple on gleam export zig-executable;
  verified linux x86_64/aarch64, windows, macos from one machine.
- Tri-target ray tracer demo (examples/demo/raytracer): byte-identical
  output on all three targets. native 0.66s/3.9MB/421KB static binary,
  node 0.12s/65MB, BEAM 1.48s/104MB. Benchmark exposed and fixed the
  positional-vs-streaming stdout writer bug and drove release-mode
  object pools. Remaining compute gap vs V8 is boxing; unboxing is the
  future work.
- Corpus: 122 passed, 0 failed, 27 skipped (all principled). CI double
  green on the run of record.

## 2026-08-20 (late night): unboxed scalars (issue #1)

- Emitter renders Int/Float/Bool-typed expressions and simple `let`
  bindings as raw i64/f64/bool (`scalar()` in zig.rs); values box only
  at polymorphic boundaries (record fields, lists, closures, captures,
  guards, case subjects). Raw div/rem helpers keep divide-by-zero -> 0.
- Native scalar ABI: module fns whose signature is entirely concrete
  scalars emit `native$name` taking/returning raw scalars, plus a boxed
  wrapper under the original name for cross-module calls, fn references
  and the entrypoint. Same-module calls (incl. self tail-call loops with
  raw `var` params) go native. Structural `P.eq` only for non-scalar
  operands; scalar ==/!= compile to raw comparisons.
- Gotchas fixed along the way: unused raw locals need a `_ = x;`
  discard (boxed locals were kept "used" by their scope-exit drop);
  `panic`/`todo` clause bodies in native fns emit as bare statements
  (field access on a noreturn call is a zig error).
- Gate: corpus 122/0/27, compiler suite 6180 green, leak gate clean,
  ray tracer byte-identical (md5 7a452dda...).
- Benchmark (ReleaseFast, M-series): scalar micro (naive fib(32) + 4M
  float escape-loop) 0.08s -> 0.02s user (4x); node does 0.24s user /
  52MB, zig now 0.02s / 1.5MB. Ray tracer unchanged (0.38 -> 0.37s
  user): its hot path is Vec record math, which needs issue #2
  (record/tuple reuse + unboxed scalar fields).

## 2026-08-21: record/tuple reuse + borrowed field access (issue #2)

- Field access on a live local borrows in place: scalar-typed fields
  (`v.x` in raw context) read `(v).record.fields[i].float` with zero RC
  traffic; boxed accesses emit `P.dup(field)` instead of
  `P.recordField(P.dup(v), i)`. Move-approved locals fall back to the
  consuming path (a borrow after a transfer would leak).
- Reuse token generalized: (identifier, shape, barrier) where shape is
  cons | record(arity) | tuple(arity). Arming extends to clauses that
  match a Constructor (non-bool/nil, arity > 0) or Tuple pattern on a
  single subject with a guaranteed same-shape construction in the body
  (direct or as a call argument). dropReuseRecord/makeRecordReuse
  overwrite the record struct + field slice in place (variant retag
  free: names/labels are static); dropReuseTuple/tupleReuse the same for
  element slices. Tokens are stashed around lifted constructor-wrapper
  emission so they cannot escape into a lifted fn's body.
- Gate: corpus 122/0/27 leak-clean, 3519+2 compiler tests (the
  copyright test now skips docs/). Ray tracer 0.37 -> 0.21s user
  (1.8x), wall 0.66 -> 0.49s (sys-time PPM writes now dominate), output
  byte-identical (md5 7a452dda...). Scalar micro and list-churn
  unchanged.

## 2026-08-21 (later): scratch allocator + borrowed ABI (issue #4a)

- The "sys-time PPM writes" diagnosis above was wrong: 0.28s sys was
  230k page reclaims from `P.allocator = page_allocator` — every FFI
  scratch allocation (one per int.to_string, one per builder growth) was
  an mmap/munmap syscall pair. Now smp_allocator. Ray tracer 0.49 ->
  0.14s wall (user 0.21 -> 0.14 too; the churn polluted user time), at
  node parity (0.12s) in 4.2MB RSS vs node's 65MB. RSS +0.3MB from smp
  pools.
- Borrowed ABI phase 1: fns whose every param use is a field-access
  container (conservative: bare use, rebind, lambda mention, or guard
  use disqualifies; TCO fns excluded; scalar params trivially eligible)
  emit `borrowed$name` — params carry no reference, callers pass live
  locals directly / box pure scalars inline / temp+drop anything else
  (temps bound in arg order to keep left-to-right evaluation). Public
  name stays an owned-convention wrapper. Vec micro (10M add/scale/dot)
  0.34 -> 0.28s user vs node 0.23s.
- Gate: corpus 122/0/27 leak-clean, compiler suite green, ray tracer
  byte-identical.
