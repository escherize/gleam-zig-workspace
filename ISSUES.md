# Issues

Local tracker. One line of status; details link into `.notes/` where a
design exists. Move finished items to the Done section with the commit.

## Open

### perf
- **#1 Unboxed scalars, phase 2: typed locals + native fn ABI.** The
  compute gap vs V8 (5.5x, ray tracer) is boxed-value overhead. Phase 1
  (raw scalar arithmetic subtrees) in progress. Phase 2: locals with
  concrete Int/Float/Bool types as raw i64/f64/bool; private fns with
  concrete scalar signatures go native; box only at polymorphic
  boundaries. Emitter has full types via `TypedExpr::type_()`.
  Sketch: `.notes/09-ideas.md`.
- **#2 Record/tuple FBIP reuse.** Extend the cons-cell token discipline
  (dropReuseCons/consReuse) to records and tuples. Vec math in the ray
  tracer is the motivating workload.
- **#3 Branch-aware last-use dataflow.** Replace the conservative
  single-straight-line-use rule with backward liveness + per-clause
  compensation drops. Design: `.notes/09-ideas.md`. Gate: differential
  corpus + DebugAllocator double-free traps.
- **#4 Borrowing inference.** Read-only params skip RC traffic. Needs a
  per-function owned/borrowed ABI split inferred module-graph-wide;
  public fns keep the owned convention.
- **#5 String buffer sharing.** Strings copy on construction and slice
  (naive-RC decision). Restore shared buffers with offset/length views
  (bit arrays already do this).

### gaps
- **#6 Non-byte-aligned bit arrays, utf16/32 segments.** Byte-aligned
  only today; sub-byte sizes panic. Needs a bit-level cursor.
- **#7 Unicode: casing tables + UAX-29 graphemes.** ASCII case/trim,
  codepoint "graphemes". Needs data tables; zig std has neither.
- **#8 Dict is an O(n) assoc list.** Port the HAMT from upstream
  dict.mjs.
- **#9 Windows.** argv FFI is posix-only (process.Args.initAllocator
  needed); paths, CI runner, and testing the x86_64-windows binaries we
  already cross-compile.
- **#10 Mutual tail recursion is stack-bound** (JS parity; self-calls
  loop). zig `@call(.always_tail)` could exceed the contract.

### features
- **#11 Single-file zig source export.** `gleam export zig-source
  --single-file`: namespace-struct wrapping + inlined prelude, one
  runnable .zig. Sketch: `.notes/09-ideas.md`.
- **#12 Toolchain auto-fetch.** Phase 6 remainder: first build fetches
  the pinned zig tarball instead of GLEAM_ZIG + manual download.
- **#13 gleam_native v2.** Event loop, buffered stream writers,
  non-posix. Handle boxes leak a few bytes each by design (alive-flag
  safety); a generation-checked handle table removes that.

### bugs
- **#14 gleam run reports exit 0 on signal death.** A segfaulting
  binary surfaced as exit 0 (seen with Ackermann). Map signal death to
  nonzero.

## Done

(nothing yet — opened 2026-08-20)
