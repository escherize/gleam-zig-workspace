# Pause distribution under reference counting

Refcounting has no stop-the-world collection, which is why this target claims
no GC pauses. That claim is true and it is not the same as "bounded pause": a
`drop` that reaches zero frees transitively, so releasing a large structure
does an unbounded amount of work at a point the program does not choose.

Nobody had measured it. Every other benchmark on this project reports a total,
and a total averages away exactly the thing a latency-sensitive caller cares
about. Measured 2026-08-28, Apple M4 Max, ReleaseFast, gleam-zig at d1ba46d2a.

## What the pause actually costs

Releasing one binary tree, timed per release, 20,000 samples at each size:

    nodes freed    p50        max/p50
        511      1.9 us        5x
      2,047      8.4 us        6x
      8,191     39.8 us       20x
     32,767    158.2 us       13x

Four times the nodes costs about four times the time. The release is linear in
what it frees, and the tail is allocator noise rather than a different code
path.

Full distribution at 8,191 nodes:

    p50     38.5 us
    p99     48.2 us
    p99.9   79.4 us
    max    258.5 us

## The number that looks alarming and is not

A first pass over a mixed workload, trees of depth 1 to 16 in rotation, gave
p50 12 us against a max of 4.5 ms: a 371x spread. That is not runtime
nondeterminism. It is the workload: a depth-16 tree is 4,000 times the size of
a depth-1 tree, so of course its release costs more.

Holding size fixed drops the spread to 6x. **The cost is predictable from the
size of what you release**, which is the useful property. It is the opposite of
a GC pause, where the cost depends on global heap state a caller cannot see.

## What this means for latency-sensitive work

Two honest readings, and which one matters depends on the caller.

Good: no global pause, and no pause that depends on anything but the structure
being freed. A caller that keeps its structures small has a tail measured in
microseconds, and one that knows its structure sizes can predict its own tail.

Bad: freeing a large structure is still a single uninterruptible operation.
158 us to release 32,767 nodes is a real stall, and it lands wherever the last
reference happens to die rather than where a scheduler chooses. For a trading
engine or anything with a hard tail budget, that is a constraint to design
around: keep hot-path structures small, or arrange for large releases to happen
off the critical path.

## Against node and the BEAM

Same workload, 2,000 releases of a depth-12 tree, total wall time:

    zig      0.61 s
    node     0.88 s
    erlang   1.95 s

Throughput only. Producing comparable *distributions* for node and the BEAM
means instrumenting each runtime's collector, which this does not do, so the
honest statement is that zig is faster in total and the pause comparison is
unmeasured. A GC pause and a transitive drop fail differently and a total
cannot distinguish them.

## Reproducing

The harness times `P.drop` directly on a tree built by emitted code, so no
Gleam-side timing allocation is folded into the sample. It lives in the session
scratchpad rather than the repo because it depends on a build tree layout;
rebuild it by compiling a tree program with `pub fn make` and `pub fn sum`,
then linking a Zig main that brackets `P.drop` with
`std.Io.Clock.now(.awake, io)`.
