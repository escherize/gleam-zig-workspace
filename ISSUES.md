# Issues

Local tracker. One line of status; details link into `.notes/` where a
design exists. Move finished items to the Done section with the commit.

## Open

### perf
- **#3b Full backward liveness.** The scoped per-clause version
  shipped (#3a); remaining: uses spread across MULTIPLE statements
  before the final case, multi-use-per-clause last-use precision, and
  liveness through nested block/pipeline tails — the full
  `.notes/09-ideas.md` design. Lower urgency now: the accumulator
  pattern is covered.
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

- **Guess-iterate-observe round: scalar guards + pattern-binding moves.**
  (2026-08-21, gleam@72f7de0d5) Guards on scalar comparisons render as
  raw compares (were dup + structural-eq helper); pattern bindings with
  one straight-line body use transfer at the use. Coin change 2.27 ->
  1.25 -> 0.81s — ahead of node (0.85), BEAM JIT still wins CPU (0.46).
  Docs site gained a five-workload benchmark scoreboard with the losses
  shown at full size (docs@e9ba73872). Corpus 122/0/27 each step.

- **#3a Per-clause last-use moves.** (2026-08-21, gleam@ac14cc585)
  Scoped branch-aware liveness: bindings whose region ends in a case
  with at most one straight-line use per clause move per clause
  (compensation drops in zero-use clauses; emission-time assert proves
  consumption). Covers list.fold/TCO accumulators — with rc==1 finally
  reaching the append, in-place string append fires: 200k-piece fold
  8.6s -> 0.02s (430x; node 0.48s). Coin change 2.53 -> 2.27s. Corpus
  122/0/27 in Debug (leak + double-free gates), edge smoke leak-clean.

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
