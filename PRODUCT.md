# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static HTML/CSS (single self-contained page + logo SVG assets), served from
GitHub Pages at `escherize.github.io/gleam-zig` (repo path `/docs`, with
`.nojekyll`). Google Fonts allowed; no build step, no framework.

## Users

1. **Curious systems / Zig developers who have never touched Gleam.** They
   want the "why would I want a typed FP language that lowers to Zig" answer
   and a copy-pasteable getting-started that assumes zero Gleam knowledge.
2. **Evaluators / skeptics** deciding whether the project is real or a toy.
   They need receipts up front — corpus parity numbers, the leak gate, CI —
   and an honest-limits section treated as a feature.

## Product Purpose

A documentation site for **gleam-zig**: an unofficial fork of the Gleam
compiler adding a `zig` compilation target. Gleam source compiles to readable
Zig that builds to a dependency-free native binary — no VM, no GC. The site
exists so a visitor can understand the architecture, run it themselves, and
audit every claim. Success: a Zig developer gets a native binary from Gleam
source in minutes; a skeptic finds the verification method and the limits
without digging.

## Positioning

The fourth Gleam backend (after official Erlang/JS and by analogy with the
author's gleam-clj). Mechanism a neighbor could not truthfully copy: it is a
fork of the real Gleam compiler (same parser, same type checker, codegen from
the typed AST), the standard library's pure bulk is Gleam compiling itself,
memory is compile-time reference counting (Perceus-style: dup/drop insertion,
last-use moves, cons-cell reuse) with every corpus run leak-checked, and all
claims are verified against the official compiler's JavaScript target as an
oracle (byte-identical stdout).

## Operating Context

Visitor likely arrives from GitHub (escherize/gleam-zig) or a link aboard a
systems-programming discussion. Reads on desktop mostly; must hold up on
mobile. Copy-paste of shell blocks into a terminal is a primary interaction.

## Capabilities and Constraints (repo truth — the site states these, not the brief's idealizations)

- **Architecture:** uniform tagged-union `Value` runtime representation
  (prelude.zig, 1161 lines); custom types are name-tagged records; `case`
  compiles to sequential per-clause checks with an `unreachable` fallthrough
  (exhaustiveness proven by Gleam's type checker). NOT per-type Zig tagged
  unions; NOT `!T` error unions (Ok/Error are records). The site must not
  claim those.
- **Memory:** Perceus-style compile-time RC, not arenas/GC. Debug builds
  leak-check at exit (exit 2 on any live allocation); release uses pooled
  fast allocator. List-churn benchmark: 236.7MB (leak-everything) -> 2.3MB.
- **Unboxed scalars (2026-08-20):** Int/Float/Bool exprs + locals emit raw
  i64/f64/bool; all-scalar-signature fns get a native raw ABI. Scalar micro
  (fib(32)+4M float loop): 0.08s -> 0.02s user; node 0.24s / 52MB vs zig
  0.02s / 1.5MB.
- **Integers are i64 with wrapping arithmetic** — diverges from BEAM bignums
  and JS f64; one rosetta program skipped for exactly this. No bigint lib.
- **Tail calls:** self tail-calls become while loops; mutual recursion is
  stack-bounded. No guaranteed TCO in Zig.
- **Oracle:** official compiler's JavaScript target (node), normalised
  stdout diff; the ray tracer demo additionally runs tri-target
  (erlang/js/zig) with byte-identical output (md5 7a452dda...).
- **Numbers (run of record, 2026-08-20):** corpus 122 passed / 0 failed /
  27 skipped (skips classified: 15 compile on neither target, 9 missing hex
  deps, 2 need absent externals, 1 int-overflow divergence). Tour 59,
  Rosetta 63. Compiler suite 6180 tests. CI workflow `zig-target` reruns
  the corpus + leak gate on every push/PR.
- **Native output:** `gleam export zig-executable` -> ReleaseFast static
  binary (ray tracer: 421KB, 0.66s, 3.9MB RSS vs node 0.12s/65MB, BEAM
  1.48s/104MB — honest: V8 still wins the record-math ray tracer);
  `--target-triple` cross-compiles (verified linux x86_64/aarch64, windows,
  macos from one machine).
- **Stdlib:** pure-Gleam bulk self-hosted (19 modules); hand-written Zig
  externals core is 77 fns / 660 lines (gleam_stdlib.zig) — the one layer
  that can be silently wrong; forks exist for simplifile, argv, envoy, plus
  gleam_native (threads, TCP, sleep, monotonic time).
- **Packaging truth:** emitted modules are plain importable `.zig` files
  (the generated entrypoint itself does `@import("pkg/module.zig")` and
  calls `main()`); public fns use the boxed `Value` ABI, all-scalar fns also
  get a raw native ABI. Single-file `.zig` export and toolchain auto-fetch
  are tracked issues (#11, #12), NOT shipped — the site labels them planned.
- **Limits to state plainly:** no BEAM concurrency/OTP (native threads via
  gleam_native only); i64 divergence; mutual recursion stack-bounded; ASCII
  case/trim + codepoint "graphemes" (no Unicode tables); dict is an O(n)
  assoc list; strings copy on construction/slice; non-byte-aligned bit
  arrays unsupported; posix-only argv (Windows untested); FFI-backed hex
  packages need Zig shims.

## Brand Commitments

- Name: **gleam-zig**. Unofficial; not affiliated with the Gleam core team —
  the site must say so.
- Visual world (user-pinned): "two-language split" — Gleam pink #FFAFF3
  (ink #151515) marks the source side; Zig amber #F7A41D dominates the
  output/runtime side; hexes sampled from the real logos (Lucy the star, the
  Zero Ziguana / ZIG mark), never invented. The compile (pink -> amber) is
  the throughline. Zig-idiom structural flourish, amber+ink+white dominant.
- Structure/tone/craft bar: mirror the gleam-clj site
  (escherize/gleam-clj docs/index.html) — receipts strip, compile panels,
  sticky TOC, limits grid — with every JVM fact retargeted to Zig/native.
- Voice: precise, unhyped; every claim paired with how it was verified;
  honest-limits section is a feature.
- Display face: Google Fonts, with character, NOT Inter/Fraunces/Space
  Grotesk/Geist (user-pinned).

## Evidence on Hand

- Corpus/harness: `examples/harness.py`, run of record in `.notes/07-status.md`
  (122/0/27), CI `gleam/.github/workflows/zig-target.yml`.
- Benchmarks: ray tracer README (`examples/demo/raytracer/README.md`) with
  tri-target table + md5; scalar micro numbers in `.notes/07-status.md`;
  list-churn RC numbers.
- Generated-code examples: real emitter output available by compiling any
  example (`examples/_run/build/dev/zig/...`).
- Logos: Gleam Lucy SVG (reusable from gleam-clj assets); Zig zero-ziguana /
  ZIG mark to fetch from ziglang (official logo repo). 
- **Absences (do not fabricate):** no differential fuzzing campaign has run
  against this target (unlike gleam-clj's 20k-case fuzz) — the site must not
  claim one; no external real-world Zig consumer exists yet; no released
  binaries/installer (build-from-source only); README corpus figure (129)
  predates the current run of record (122/0/27 after reclassification) — use
  the fresh number and say skips are classified.

## Product Principles

1. Numbers on the page are true, current, and traceable to the repo; if a
   claim has no oracle yet, the page says so.
2. Zero Gleam assumed: every Gleam concept introduced is shown beside its
   emitted Zig.
3. Honest limits are a feature, not fine print — deliberate edges get the
   same design attention as wins.
4. The reader can act: every "run this" block is copy-pasteable and real.
5. Readable output is the product: show real emitted code, not idealized
   pseudocode.

## Accessibility & Inclusion

Standard web baseline: semantic landmarks, prefers-reduced-motion honored,
prefers-color-scheme both themes, WCAG AA contrast on both, code blocks
horizontally scrollable on mobile without page scroll.
