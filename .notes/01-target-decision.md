# Target decision: systems language, C or Zig emission

Systems languages won over managed targets once the scope shrank to JavaScript-target parity. The remaining open question is the emission language: C compiled by `zig cc`, or Zig directly.

## Managed targets lost on a single criterion each

Full first-round matrix, scored 1 to 5 against the eight criteria plus semantic fit and effort:

| Target | Async | Compile speed | Perf | Memory | Startup | Ecosystem | Semantic fit | Effort |
|---|---|---|---|---|---|---|---|---|
| Go (transpile) | 5 | 5 | 4 | 4 | 5 | 4 | 2 (no TCO) | med |
| JVM (Loom) | 5 | 3 | 4 | 2 | 1 | 5 | 2 (no TCO) | med-high |
| .NET | 4 | 4 | 4 | 3 | 3 | 4 | 4 (IL `tail.`) | med |
| Native LLVM | 1 | 2 | 5 | 5 | 5 | 1 | 3 (own GC) | huge |
| Rust (transpile) | 3 | 1 | 5 | 5 | 5 | 4 | 1 | high |
| WASM (WasmGC) | 2 | 4 | 3 | 4 | 5 | 2 | 4 (`return_call`) | med-high |
| LuaJIT | 3 | 5 | 3 | 5 | 5 | 2 | 5 | low |
| Python | 2 | 5 | 1 | 2 | 2 | 5 | 2 | low |

Eliminations: JVM fails startup and memory. Python fails performance. LuaJIT and Lua-class targets fail ecosystem and sit too close to the existing JavaScript target to justify the work. Go was the best managed score, but a systems target dominates it on memory and startup once the scheduler requirement disappeared, and Go's ecosystem is reachable from nothing (no C ABI story as clean as a native target's).

## Systems-language matrix after the scope correction

Two costs vanished when scope dropped to JS parity: the scheduler (async is FFI-delegated) and full TCO (self-tail-calls compile to loops, mutual tail recursion may overflow, the JS target already accepts this). GC and closures remain, but both are fixed one-time compiler passes (RC insertion, closure conversion), not per-target penalties. The differentiators that remain:

| Target | User compile speed | Stdlib FFI authoring | RC freedom | Cross-compile | Target stability | Effort |
|---|---|---|---|---|---|---|
| C via `zig cc` | 5 | 2 | 5 (full control, `musttail`) | 5 | 5 (C99 frozen) | medium |
| Zig emission | 4 | 4 | 5 (`@call(.always_tail)`) | 5 | 2 (pre-1.0, breaks per release) | medium |
| Rust emission | 1 | 5 | 2 (`Rc` or unsafe) | 4 | 5 | med-high |

Rust is eliminated: rustc runs on generated code inside every user's `gleam build`, so its compile speed violates the fast-compiles criterion for every user forever, and its ownership model blocks the Perceus reuse optimization that motivated the memory design.

## The open call: C emission vs Zig emission

The decision lever is the expected volume of user-written FFI.

- **C emission** protects users you do not control. C99 never changes, so codegen, the runtime, and third-party FFI packages never migrate. Cost: writing the prelude, RC runtime, and hundreds of stdlib externals in raw C.
- **Zig emission** makes the code you write once (runtime, stdlib externals) much nicer to author, and `zig cc` tooling comes along either way. Cost: codegen, runtime, and every published FFI package track Zig's breaking releases (see 04-zig-pin.md).

Current lean: start with Zig emission for the prototype (faster to a working backend), keep the emitted subset boring enough that a later port of codegen output to C is mechanical. Revisit before any public release.

## Non-obvious facts that shaped the ranking

- Gleam's immutability makes the heap acyclic, so plain reference counting is sound with no cycle collector. This removed "write a GC" from every systems target's cost.
- clang `musttail` and Zig `@call(.always_tail)` both guarantee tail calls; guaranteed TCO is available on both emission choices even though the JS-parity scope no longer strictly requires it.
- `zig cc` gives hermetic cross-compilation from a single ~45MB tarball regardless of whether we emit C or Zig. The toolchain choice is independent of the emission-language choice.
