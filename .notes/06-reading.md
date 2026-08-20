# Reading list and prior art

Ordered. The first two are prerequisites for phase 3; the rest inform design reviews.

## Papers (read in this order)

1. **Counting Immutable Beans** - Ullrich, de Moura. Lean 4's RC: simpler precursor to Perceus, best first exposure to compile-time dup/drop insertion.
2. **Perceus: Garbage Free Reference Counting with Reuse** - Reinking, Xie, de Moura, Leijen, PLDI 2021. The core design: precise RC, drop specialization, reuse analysis, borrowing.
3. **Reference Counting with Frame-Limited Reuse** - Lorenzen, Leijen. Fixes reuse pathologies in original Perceus; read before implementing the reuse pass, not after hitting the pathologies.

## Compilers to read

- **Roc** (github.com/roc-lang/roc): closest living relative. Functional language, RC with in-place reuse, monomorphized, native. Steal: RC runtime layout, reuse machinery, dual-backend strategy (fast dev backend + LLVM release backend), platform/application split as the model for a pluggable runtime. Note: Roc has no actor model; it outsources async to the platform, which validates our JS-parity scope. Caveat: team of paid engineers, ~6 years in, still pre-0.1, compiler being rewritten from Rust to Zig since 2025. Calibrate effort estimates accordingly.
- **Koka** (github.com/koka-lang/koka): Perceus reference implementation. Read `kklib` (the C runtime) for header layout, drop specialization output, and the FBIP calling conventions.
- **Lean 4 runtime**: production RC on immutable data at scale.
- **Chicken Scheme / Gambit**: the emit-C playbook (driver structure, trampolines, toolchain wrangling), relevant if the C-emission fallback triggers.
- **Pony / ORCA**: per-actor GC with message passing. Only relevant if a real actor runtime ever returns to scope.

## Gleam-side references

- `gleam/compiler-core/templates/prelude.mjs` (1,605 lines): the semantics contract to port.
- `gleam/compiler-core/src/javascript/` : the backend to copy structurally.
- gleam-lang/gleam discussions on third targets: core team has declined new in-tree targets historically; the fork plan assumes no upstreaming.

## Toolchain references

- Zig 0.16 release notes (colorless async I/O, incremental compilation) and the 0.15 "Writergate" notes: the churn record that motivated the pin strategy in 04-zig-pin.md.
- clang `musttail` attribute docs and Zig `@call(.always_tail)`: guaranteed-TCO options on each emission language.
- TigerBeetle's build setup: the exact-pin precedent for Zig toolchains.
