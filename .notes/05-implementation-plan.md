# Implementation plan

Six phases, each with a verification gate. Phases 1 to 3 produce a compiler that runs real Gleam programs natively; 4 to 6 make it usable by other people.

## Phase 1: plumbing (compiler accepts the target)

- Add the variant to `Target` in `compiler-core/src/build.rs:63` and to `TargetCodegenConfiguration` at `build.rs:171`.
- Chase the 24 files matching on `Target::` until the workspace compiles. Every match arm is a decision recorded in code.
- Wire `gleam.toml` `target = "native"` (name TBD) and the CLI flag in `compiler-cli`.
- Gate: `gleam build --target native` reaches codegen and fails with "unimplemented", not a plumbing error.

## Phase 2: codegen core (no RC yet, leak everything)

- New module beside the others: `compiler-core/src/native.rs` plus `native/expression.rs`, `native/decision.rs`, copying the JavaScript backend's layout (see 02-js-target-anatomy.md).
- Prelude: port `templates/prelude.mjs` semantics (custom types, lists, equality, division by zero, bit arrays) to the emission language. Copy the JS prelude's behavior exactly, including the weird cases; divergence here is invisible until a user hits it.
- Self-tail-call to loop conversion, mirroring `javascript/expression.rs:353` `tail_call_loop`.
- Leak all allocations. Correctness first; memory comes in phase 3.
- Gate: the language-test corpus under `test/` passes, minus stdlib-dependent cases.

## Phase 3: memory (Perceus passes)

- Target-independent IR pass pipeline per 03-memory-perceus.md: naive RC, then last-use precision, then reuse/borrowing.
- Gate per step: stdlib-free test corpus runs leak-clean under a leak-checking allocator; last-use pass fuzzed against naive RC.

## Phase 4: stdlib

- Third external implementation for `gleam_stdlib`. Size it first: grep for `@external(javascript, ...)` and count.
- Define the FFI ownership convention (borrowed in, owned out) before the first external. Write the FFI guide in the same commit.
- Gate: `gleam_stdlib` test suite passes on the native target.

## Phase 5: async FFI package

- `gleam_native` package: OS threads, an event loop, timers, file and network I/O. Mirrors the role `gleam_javascript` plays for promises.
- Thread boundary rule from 03-memory-perceus.md: deep-copy values crossing threads, refcounts stay non-atomic.
- Gate: an echo server and a concurrent-download example run.

## Phase 6: distribution

- `gleam build` fetches the pinned toolchain tarball on first use.
- Cross-compilation matrix in CI: linux-x86_64, linux-aarch64, macos-aarch64, windows-x86_64.
- Gate: a release binary of a hello-world HTTP client builds on all four from one host.

## Standing risks

- Upstream rebase drift: the fork touches 24+ files. Rebase weekly, keep target-specific code in the new modules, keep diffs to shared files minimal.
- Prelude semantic drift from the JS target: port the JS prelude's tests, not just its code.
- Phase 4 is the schedule risk; it is grind proportional to stdlib size, parallelizable, and worth automating (an external's JS implementation is often a translation template).
