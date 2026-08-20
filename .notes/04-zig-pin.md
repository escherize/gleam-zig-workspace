# Pinning Zig 0.16: viable, costs deferred not avoided

Pin Zig 0.16.0 exactly, vendor the toolchain per-project, and restrict emitted code to a boring subset. This works, but the cost is a migration debt that comes due on the OS vendors' schedule, not ours.

## Zig status (verified 2026-08-19)

- Current stable: 0.16.0, released 2026-04-14. 0.17 expected mid-2026.
- No 1.0, no timeline. Stated bar includes zero disabled tests on Tier 1 targets.
- Breaking changes per release are policy, not accident. 0.15 rewrote the entire `std.Io` Reader/Writer interface ("Writergate") and removed `usingnamespace`.
- 0.16 landed colorless async I/O and ~30ms incremental rebuilds. The async story is stabilizing but not stable.

## Why pinning works better here than for a normal codebase

- The Zig toolchain is one hermetic ~45MB tarball, no system install. `gleam build` can fetch the exact version like a dependency; users cannot have "the wrong Zig".
- Emitted code is machine-generated. We control the subset: functions, structs, `@call(.always_tail)`, own prelude, near-zero `std` usage. Stdlib rewrites like Writergate cannot break code that does not use `std`.
- Precedent: TigerBeetle exact-pins the compiler and vendors around stdlib churn. Exact-pin is the normal mode of serious Zig use.

## The four deferred costs

1. **OS bitrot forces the upgrade.** Old toolchains break against new macOS SDKs, glibc versions, and arch variants. 0.16 will one day emit binaries that fail on a machine a user owns, and that day picks the migration date.
2. **No backported fixes.** Upstream supports the latest release only. A miscompile or CVE found in 0.16 after 0.18 ships is fixed only by doing the deferred migration.
3. **FFI dialect drift.** Users writing external Zig write 0.16 Zig while docs, packages, editor tooling, and LLM training data move ahead. New Zig packages will not build on the pinned version. This cost lands on users we do not control, which is what makes it the serious one.
4. **Migration sprints are ecosystem-wide.** A version jump means codegen diffs, runtime diffs, and every published FFI package migrating in lockstep.

## Mitigations

- Keep `std` usage confined to one runtime file (allocator plus entry point). Migration surface stays measured in tens of lines for our code.
- Publish an FFI style guide that bans `std` APIs known to churn (I/O interfaces above all).
- The C-emission fallback: because the emitted subset is boring, porting the emitter's output language from Zig to C is mechanical. If Zig churn proves too expensive pre-1.0, this is the exit, and `zig cc` remains the shipped toolchain either way.

## Decision rule recorded from discussion

Expected volume of user-written FFI decides the emission language. Stdlib-only FFI authored by us: pin Zig, eat the migrations ourselves. A thriving third-party FFI ecosystem as an explicit goal: emit frozen C99 and protect users we do not control.
