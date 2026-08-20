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
