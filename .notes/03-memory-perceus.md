# Memory design: Perceus-style reference counting

Gleam is a near-ideal Perceus host: the heap is provably acyclic, control flow has no hidden exits, and the stdlib's cons-list-heavy style is exactly the workload Perceus reuse optimizes. Plain RC with compile-time insertion replaces a tracing GC entirely.

## Why plain RC is sound in Gleam

Immutable data plus no recursive value bindings means a value can only reference values that existed before it. Cycles are unconstructible. No cycle collector, no tracing, no GC pauses.

## Why Perceus beats naive RC

| Technique | Effect |
|---|---|
| Precise dup/drop insertion at last use | Values free at the earliest possible point, not scope exit. Lower peak memory |
| Drop specialization | Destructor inlined and fused with surrounding dups; most RC traffic cancels statically |
| Reuse analysis (FBIP) | Match-then-allocate of the same shape reuses the cell when refcount is 1. `list.map` and record update become in-place mutation behind pure semantics |
| Borrowing inference | Read-only parameters skip RC traffic entirely |

## Gleam-specific fit

- No exceptions. Errors are `Result`; panics kill the process. Perceus requires all control paths visible to the compiler; Koka had to fight effect handlers for this, Gleam gets it free.
- Closures: RC'd environment structs, standard closure conversion.
- Externals/FFI need an ownership convention. Simplest contract: FFI functions receive borrowed values and return owned values. Document this in the FFI guide before writing the first external, retrofitting a convention is misery.

## Atomicity decision

Non-atomic refcounts, single-threaded per Gleam-visible heap. Atomic RC costs roughly 2 to 3x on RC traffic. The JS-parity scope has no shared-memory concurrency in the language, so nothing forces atomics. If the `gleam_native` FFI package later adds threads, it must either deep-copy values across thread boundaries (the BEAM move) or freeze-and-atomically-count shared values. Deep copy is the default plan; it keeps the fast path fast.

## Value representation sketch

- Header word: refcount + type tag + reuse-relevant size class.
- Ints: unboxed i64. Floats: unboxed f64. No bignums (JavaScript-target precedent).
- Strings: UTF-8, RC'd, immutable slices share the underlying buffer.
- Custom types: tagged struct, fields are values.
- Bit arrays: RC'd byte buffer + offset/length, mirroring `prelude.mjs` BitArray semantics exactly. Copy the JS prelude's test cases.

## Compiler pipeline placement

Typed AST -> ownership/last-use analysis -> dup/drop insertion -> reuse token pass -> backend emission. Design the RC passes as a target-independent IR so the emission language (C or Zig) stays swappable. Do not braid RC insertion into the emitter the way the JS backend braids tail-call handling into expression codegen; RC correctness needs to be testable without a backend.

## Order of implementation

1. Naive RC first: dup on every bind, drop at scope exit. Correct, slow, shippable.
2. Last-use precision second. This is the correctness-sensitive pass; fuzz it against naive RC with heap-leak assertions.
3. Reuse and borrowing last. Pure optimization; only start after the stdlib test suite passes on naive RC.
