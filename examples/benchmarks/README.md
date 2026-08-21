# Benchmark sources

The one-file programs behind escherize.com/gleam-zig/benchmarks.html.
The ray tracer lives at `examples/demo/raytracer/`.

Correctness (both targets, byte-diffed, leak-checked — Debug mode):

    python3 examples/harness.py \
      examples/benchmarks/coin_change.gleam \
      examples/benchmarks/scalar_micro.gleam

`string_build` and `vector_records` use their full published sizes
(200k pieces / 10M iterations), which are too slow under the Debug
leak-checking allocator; to run them through the harness, shrink the
constant in `main` first. The published timings are ReleaseFast:

    cp examples/benchmarks/coin_change.gleam examples/_run/src/mainmod.gleam
    cd examples/_run && gleam export zig-executable --out bench
    /usr/bin/time -l ./bench
