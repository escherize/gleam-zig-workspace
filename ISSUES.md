# Issues

Local tracker. One line of status; details link into `.notes/` where a
design exists. Move finished items to the Done section with the commit.

## Open

### perf
- **#16 Latent record-pool aliasing bug (release modes).**
  ReleaseSafe/ReleaseFast builds intermittently panic "incorrect
  alignment" reading a closure's function pointer; output truncates.
  Repro: tour lesson01_use via harness, examples/_run with result.try /
  echo chains; raytracer flaky-by-build. Evidence: all record-pool
  push/pop sequences traced legal (no double-pop, no bad name encoding);
  corruption only when the record free-list recycles addresses - Debug's
  quarantine allocator and pool-free builds never show it, so a stale
  alias to a retired record survives somewhere in codegen refcount
  discipline. Candidate asymmetry: `borrowed$try` Ok-path returns
  `call1(v_fun, ...)` without dropping `v_fun` (Error path drops it).
  Pooling is now opt-in (`GLEAM_ZIG_POOL=1`) and release run modes are
  opt-in (`GLEAM_ZIG_RUN_MODE`) until fixed. Fix hunt: instrument
  makeRecordL reuse addresses vs closure env/field slots; audit borrowed-
  ABI drop placement.

- **#15 Record footprint for sum types.** Multi-constructor values
  allocate a wide header (rc + name slice + fields slice + labels
  slice) plus inline fields; allocation traffic dominates the tree
  benchmark, where node still leads (~8% at depth 21). Name-compare
  cost is NOT the problem: a pointer-identity fast path for
  `P.recordHasName` measured as noise. Options: pack the name into a
  comptime name-hash tag (u64, memcmp fallback for the astronomic
  collision case), drop the labels slice into the tag word, or pool
  records by arity. Needs a design pass before it pays.
- **#3b Full backward liveness.** The scoped per-clause version
  shipped (#3a); remaining: uses spread across MULTIPLE statements
  before the final case, multi-use-per-clause last-use precision, and
  liveness through nested block/pipeline tails — the full
  `.notes/09-ideas.md` design. Lower urgency now: the accumulator
  pattern is covered.
- **#4 Borrowing inference, phase 4.** Phases 1-3 done (2026-08-21):
  field-read-only params, transitive + self-recursive greatest-fixpoint
  inference, borrowed case subjects, borrowed pattern bindings.
  Remaining: TCO fns whose params pass through self-calls unchanged,
  cross-module borrowing (needs interface metadata), and stack
  allocation for constructions that flow only into borrowed positions
  (the vec-records loss row).
- **#5 String buffer sharing.** Strings copy on construction and slice
  (naive-RC decision). Restore shared buffers with offset/length views
  (bit arrays already do this).

### gaps
- **#6 Non-byte-aligned bit arrays, utf16/32 segments.** Byte-aligned
  only today; sub-byte sizes panic. Needs a bit-level cursor.
- **#7 Unicode: casing tables + UAX-29 graphemes.** ASCII case/trim,
  codepoint "graphemes". Needs data tables; zig std has neither.
- **#9 Windows.** argv FFI is posix-only (process.Args.initAllocator
  needed); paths, CI runner, and testing the x86_64-windows binaries we
  already cross-compile.
- **#10 Mutual tail recursion is stack-bound** (JS parity; self-calls
  loop). zig `@call(.always_tail)` could exceed the contract.

### features
- **#13 gleam_native v2.** Event loop, buffered stream writers,
  non-posix. Handle boxes leak a few bytes each by design (alive-flag
  safety); a generation-checked handle table removes that.

### bugs
- **#14 gleam run reports exit 0 on signal death.** A segfaulting
  binary surfaced as exit 0 (seen with Ackermann). Map signal death to
  nonzero.

## Done
- **Native ABI for list parameters.** (2026-08-22, gleam@cd597909b)
  Functions with scalar-or-list parameters returning a scalar now
  travel raw: lists as borrowed spine pointers, zero RC ops per
  recursion level — the dup/wrap/drop round trips through the Value
  union that LLVM could not optimize away are gone. Soundness rules:
  lists are parameter-only (a returned spine would have no owner),
  wrappers release owned list Values, raw locals box owningly at
  polymorphic uses and captures (`P.dupList`), the raw call fast path
  requires every list argument's owner to outlive the call, and TCO
  loops keep the all-scalar rule. Coin change 900: 0.26 -> 0.13s user
  (2x; hand-written zig on the same algorithm is 0.12s). All other
  benchmarks unchanged. New `tree` benchmark (allocation-heavy sum
  types): zig 1.07s vs node 0.99s at depth 21 — spawned #15.
  Corpus 119/0/30 leak-clean; workspace suite green.
- **#12 Toolchain auto-fetch.** (2026-08-22, gleam@2fc4a9be7)
  First zig-target command resolves the pinned zig 0.16.0 itself:
  GLEAM_ZIG override, then gleam's global cache, then a PATH zig
  reporting exactly 0.16.0, else download from ziglang.org with sha256
  verification and tar extraction into `<cache>/gleam/zig/`.
  `gleam build --target zig` stays fetch-free. Corpus 119/0/30 twice -
  vendored toolchain vs freshly fetched cache copy.
- **#8 Dict HAMT.** (2026-08-21, stdlib@c5a195e, prelude@6fa94bd11)
  Assoc list -> hash array mapped trie (32-way, 5 hash bits/level,
  nodes are RC'd Values so the leak gate covers them). 10k-key
  insert+lookup 1.12s -> 0.011s (100x): now 6x node, 10x BEAM, 8MB vs
  36MB. Verified with a 60-case differential test against the JS
  target. Iteration order is hash order now (was always unspecified;
  matches erlang where the assoc list matched V8), so gleam/set joined
  the harness's unspecified-order list. Corpus 123/0/30.

- **#4e Nested flat records + width cap.** (2026-08-21, gleam@90eff8361)
  Flat fields may be other flat structs (least-fixpoint eligibility,
  recursive box/unbox, chained field paths). Nesting alone made the ray
  tracer 16% slower — wide structs are copied by value at every
  boundary, and Sphere crosses one ~1.4M times per render — so
  eligibility gained a 4-scalar width cap: Vec stays flat, Sphere stays
  boxed, ray tracer back to 0.074s. Narrow nested case (Seg of two
  Points) 0.331 -> 0.049s, 6.7x. Corpus 126/0/27; harness timeout
  raised 20s -> 60s after a near-limit program produced two false
  failures.

- **#4d Flat record ABI.** (2026-08-21, gleam@fbe68ae62) Single-
  constructor all-scalar records travel as zig structs inside their
  module: `flat$Type` structs, `flat$fn` ABI + boxed wrapper, flat
  locals, tag-free pattern matching, box$/unbox$ at every polymorphic
  boundary. Vec micro 0.17 -> 0.03s (last loss row flips: 2x the BEAM),
  ray tracer 0.08 -> 0.07s byte-identical. Corpus 126/0/27, 6180 tests.
  Also corrected two published measurement errors: erlang rows had been
  wall time vs everyone else's CPU (ray tracer headline 18x -> 4.7x),
  and node re-measured best-of-3 (string 24x -> 6x). Docs carry a dated
  correction; every page now quotes user CPU time.

- **Bare-file export mode.** (2026-08-21, gleam@89f6e29a7)
  `gleam export zig-executable file.gleam` / `zig-source file.gleam`:
  temp-project scaffolding (stdlib via $GLEAM_ZIG_STDLIB or ancestor
  gleam-stdlib/ search; root canonicalised past the macOS /var
  symlink). Write 1 gleam file, get 1 native binary: bare raytracer.gleam
  -> 399KB executable, byte-identical PPM; also exports to one runnable
  .zig. 6180 tests green.

- **#11 Single-file zig source export.** (2026-08-21, gleam@adb8bee44)
  `gleam export zig-source`: modules and native files wrapped in
  path-keyed namespace structs, imports rewritten, prelude inlined,
  entrypoint appended — one runnable .zig, `zig run` with no gleam.
  Ray tracer single file byte-identical; simplifile FFI path verified.
  Surfaced and fixed two latent bugs multi-file builds hid: constants
  emitted without target-support checks (dangling references to
  never-emitted fns), and the nested-sequence use counter not stopping
  at rebinds (phantom-armed pattern moves; caught by the consumption
  assert). Corpus 124/0/27, 6180 tests.

- **Inline record fields + benchmark dossier page.** (2026-08-21,
  gleam@039b8430b, docs@6c63486ea) Records arity <= 4 store fields
  inside the Record struct (fields slice points at inline storage;
  readers untouched): ray tracer 0.12 -> 0.08s (1.5x node), vec micro
  0.26 -> 0.17s (ahead of node; BEAM 0.13 keeps the last lead). New
  /benchmarks.html dossier page: log-log time*memory scatter of all 15
  runs, per-benchmark source + emitted code + dated history, real
  reproduction commands backed by sources committed at
  examples/benchmarks/ (workspace@600ccf0). Corpus 122/0/27.

- **#4c Self-recursive borrowing + borrowed pattern bindings.**
  (2026-08-21, gleam@831c1eca2) Greatest-fixpoint inference (seed all
  candidates fully borrowed, clear flags until stable) lets self- and
  mutually-recursive calls justify each other's borrows; pattern
  bindings from borrowed subjects with borrow-only uses skip dup and
  drop entirely. Coin change 0.81 -> 0.28s — zero RC ops per call,
  beats BEAM JIT (0.46 CPU) and node (0.85). Corpus 122/0/27
  leak-clean, all other benches unchanged.

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
