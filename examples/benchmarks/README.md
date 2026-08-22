# Benchmark sources

The one-file programs behind escherize.com/gleam-zig/benchmarks.html.
The ray tracer lives at `examples/demo/raytracer/`.

Correctness (both targets, byte-diffed, leak-checked — Debug mode):

    python3 examples/harness.py \
      examples/benchmarks/coin_change.gleam \
      examples/benchmarks/scalar_micro.gleam

`string_build` and `vector_records` carry harness-sized constants (20k
pieces / 1M iterations) so every program in this directory runs under
the Debug leak-checking allocator. The published timings use the full
sizes named in each file's header comment, built ReleaseFast:

    cp examples/benchmarks/coin_change.gleam examples/_run/src/mainmod.gleam
    cd examples/_run && gleam export zig-executable --out bench
    /usr/bin/time -l ./bench
