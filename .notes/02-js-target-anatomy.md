# JavaScript target anatomy: the template for the new backend

The JavaScript backend is roughly 8,000 lines of Rust plus a 1,605-line runtime prelude, and it defines the parity bar for the native target: no scheduler, no OTP, self-tail-call loops only, async via FFI.

All paths relative to `gleam/compiler-core/`.

## Backend layout and sizes

| File | Lines | Role |
|---|---|---|
| `src/javascript.rs` | 1,663 | Module-level codegen: imports, exports, function declarations, prelude usage registration |
| `src/javascript/expression.rs` | 3,936 | Expression codegen, the bulk of the work |
| `src/javascript/decision.rs` | 2,546 | Pattern-match compilation (decision trees from the `exhaustiveness` module) |
| `src/javascript/import.rs` | 293 | Import path resolution |
| `src/javascript/typescript.rs` | 1,312 | `.d.ts` generation, optional, skip for native |
| `templates/prelude.mjs` | 1,605 | Runtime: custom type base class, lists, bit arrays, equality, division |

Comparison point: `src/erlang.rs` is 4,411 lines in one file. The JavaScript layout (module file plus expression/decision split) is the one to copy.

## Target registration points

- `src/build.rs:63` - `pub enum Target { Erlang, JavaScript }`. The new variant starts here.
- `src/build.rs:171` - `TargetCodegenConfiguration`, carries per-target codegen options.
- `Target::` is matched in 24 files under `compiler-core/src`. Adding a variant means the compiler errors on every non-exhaustive match, which is the to-do list for plumbing.

## Prelude mechanics

- `src/javascript.rs:35` - `pub const PRELUDE: &str = include_str!("../templates/prelude.mjs");`. The prelude ships inside the compiler binary and is written into the build directory at codegen time.
- `src/javascript.rs:217-224` - prelude symbols (`Ok`, `Error`, list constructors, etc.) are imported per-module only when used. The native backend needs the same usage-tracking so the emitted translation unit stays small.

## Tail calls: the precedent that shrank the project

- `src/javascript/expression.rs:243-246` - the expression generator tracks `tail_recursion_used` while walking a function body.
- `src/javascript/expression.rs:346-353` - if set, `tail_call_loop` wraps the body in a loop and rewrites self-tail-calls as parameter reassignment plus `continue`.

Mutual tail recursion is NOT handled; deep mutual recursion overflows the stack on the JavaScript target and this is accepted. The native target inherits this contract. With Zig `@call(.always_tail)` or clang `musttail` available, the native target can exceed the contract cheaply, but nothing in stdlib requires it.

## What the JavaScript target omits, and the native target may also omit

- No `gleam_otp`, no processes, no message passing. Concurrency belongs to the platform.
- Async is wrapped by a separate FFI package (`gleam_javascript` wraps promises). Native analog: a `gleam_native` package wrapping OS threads plus an event loop.
- Ints are JavaScript numbers, not bignums; the Erlang target has bignums. Precedent: targets may pick a pragmatic numeric representation. Native choice: i64 (see 03-memory-perceus.md for boxing interaction).

## Stdlib FFI surface

`gleam_stdlib` (separate repo, hex package) implements externals twice: `.erl` files and `.mjs` files. A native target adds a third implementation of every external. This is the largest single work item in the project and is pure grind, not design. Count them early: grep the stdlib for `@external(javascript, ...)` to size the list.
