# Issues

Local tracker. One line of status; details link into `.notes/` where a
design exists. Move finished items to the Done section with the commit.

## Open

### perf
- **#3 Branch-aware last-use dataflow.** Replace the conservative
  single-straight-line-use rule with backward liveness + per-clause
  compensation drops. Design: `.notes/09-ideas.md`. Gate: differential
  corpus + DebugAllocator double-free traps. Now the top perf item:
  accumulators used once-per-clause (list.fold, TCO acc params) never
  reach rc==1, so the in-place string append cannot fire — 200k-append
  bench runs 8.6s vs node 0.5s. Per-clause moves fix string building,
  TCO accumulators, and unlock more reuse arming in one design.
- **#4 Borrowing inference, phase 3.** Phases 1-2 done (2026-08-21):
  field-read-only params, transitive fixpoint over the module call
  graph, borrowed case subjects. Remaining: TCO fns whose params pass
  through self-calls unchanged, and cross-module borrowing (needs
  interface metadata).
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

- **#4b Transitive borrowing + borrowed subjects + capacity strings.**
  (2026-08-21, gleam@f6b100fc3) Borrow inference runs to fixpoint
  (param passed to a borrowed position is itself borrowing — covers
  intersect-style chains); case subjects that are live locals borrow in
  place (no dup/drop, reuse unaffected for owned subjects); string
  headers carry allocated capacity so `<>` with an unshared left
  operand appends in place with doubling. Straight-line/pipeline append
  chains now amortized linear; multi-clause accumulators still copy
  (blocked on #3). Ray tracer 0.13-0.14s, vec micro 0.27s. Corpus
  122/0/27 leak-clean.

- **#4a Borrowed param ABI + scratch allocator fix.** (2026-08-21,
  gleam@89ad2fa24) Scratch allocator page_allocator -> smp_allocator:
  the ray tracer's 230k mmap/munmap pairs (one per formatted number)
  were costing more than rendering — 0.49s -> 0.14s wall, now at node
  parity (0.12s) in 4MB vs 65MB. Borrowed ABI phase 1: fns whose params
  are only field-read emit `borrowed$name` (caller passes without dup,
  callee never drops; owned wrapper kept public). Vec micro 0.34 ->
  0.28s. Corpus 122/0/27 leak-clean.
- **#2 Record/tuple FBIP reuse + borrowed field access.** (2026-08-21,
  gleam@c7e257f06) Field access on a live local borrows in place (scalar
  fields: zero RC traffic; boxed: dup the field only). Reuse token is
  now shape-tagged (cons | record(arity) | tuple(arity)): a clause
  matching a record/tuple pattern whose body is guaranteed to construct
  the same shape steals the unshared allocation in place; variant retag
  free. Ray tracer 0.37 -> 0.21s user (1.8x), wall 0.66 -> 0.49s,
  byte-identical output. Corpus 122/0/27 leak-clean; other benchmarks
  unchanged.
- **#1 Unboxed scalars: raw subtrees, typed locals, native fn ABI.**
  (2026-08-20) Int/Float/Bool expressions and simple `let` bindings emit
  as raw i64/f64/bool; module fns with all-scalar concrete signatures get
  a raw `native$name` ABI plus a boxed wrapper (cross-module callers,
  fn references, entrypoint). Same-module calls and TCO loops run fully
  unboxed. Scalar micro (fib(32) + 4M-iteration float escape loop):
  0.08s -> 0.02s user, 4x, now 12x faster than node's 0.24s. Corpus
  122/0/27, 6180 compiler tests, leak gate clean, ray tracer output
  byte-identical. Ray tracer time unchanged — moved to #2.
