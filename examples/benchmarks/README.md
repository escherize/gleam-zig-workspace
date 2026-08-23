# Benchmark sources

The one-file programs behind escherize.com/gleam-zig/benchmarks.html.
The ray tracer lives at `examples/demo/raytracer/`.

Correctness (both targets, byte-diffed, leak-checked — Debug mode):

    python3 examples/harness.py examples/benchmarks/

Every program here carries harness-sized constants so it runs under
the Debug leak-checking allocator. The published timings use the full
sizes named in each file's header comment, built ReleaseFast:

    ./bench.sh tree.gleam 's/iterate(16, 10, 0)/iterate(21, 4, 0)/' 3

