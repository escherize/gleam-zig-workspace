# Project: a native compilation target for Gleam

Add a third compilation target to a fork of the Gleam compiler, scoped to parity with the existing JavaScript target, using Perceus-style reference counting for memory and Zig tooling for the native toolchain.

## The goal in one sentence

A Gleam target that scores well on all eight criteria at once: good type system, good async, good error messages, fast compiles, good performance, low memory overhead, quick startup, large ecosystem.

Neither existing target does. The Erlang target loses raw performance, startup, and native ecosystem. The JavaScript target loses the actor model and memory scaling. A native target trades differently: it keeps types, errors, compiles, performance, memory, and startup, and reaches the C ecosystem through FFI.

## Decisions made so far

| # | Decision | Status |
|---|---|---|
| 1 | Fork the gleam repo, add the target in-tree beside `erlang` and `javascript` modules | Decided |
| 2 | Scope = JavaScript-target parity, not BEAM parity. No scheduler, no OTP, no process isolation | Decided |
| 3 | Memory = Perceus-style reference counting, inserted as a target-independent compiler pass | Decided |
| 4 | Systems-language target family (C or Zig emission), not Go / JVM / .NET / Rust | Decided |
| 5 | Emit Zig directly vs emit C compiled by `zig cc` | Open. See 01-target-decision.md |
| 6 | If Zig: pin 0.16.0 exactly, vendor the toolchain per-project | Decided conditional on #5 |

## Why the scope shrank

The first plan priced in a BEAM-style runtime: green-thread scheduler, per-process heaps, message copying. The JavaScript target proves Gleam does not require this for an official target. `gleam_otp` does not exist on JavaScript; async is whatever the platform offers, wrapped by an FFI package (`gleam_javascript` wraps promises). The native target does the same: a `gleam_native` FFI package wraps OS threads and an event loop. The project is therefore: one codegen backend, one prelude with an RC runtime, one RC compiler pass, one FFI package.

## Directory layout

- `gleam/` - clone of gleam-lang/gleam (the fork target)
- `.notes/` - these notes

## Note index

- `01-target-decision.md` - decision matrices, C vs Zig emission
- `02-js-target-anatomy.md` - how the JavaScript backend works, with file:line refs
- `03-memory-perceus.md` - reference counting design
- `04-zig-pin.md` - cost model of pinning Zig 0.16
- `05-implementation-plan.md` - phases
- `06-reading.md` - papers and prior art
