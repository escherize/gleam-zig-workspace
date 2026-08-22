#!/bin/zsh
set -e
RT=/Users/bcm/dv/gleam-zig/examples/demo/raytracer
SRC=$RT/src/raytracer.gleam
G=/Users/bcm/dv/gleam-zig/gleam/target/debug/gleam
Z=/Users/bcm/dv/gleam-zig/toolchain/zig-aarch64-macos-0.16.0/zig
OUT=/tmp/rt-matrix-small.jsonl
: > $OUT
RES=("320 240" "640 480" "1280 960")
BOUNCES=(1 2 3 5 10)
timeit() { python3 -c '
import subprocess, sys, time
best = None
for _ in range(3):
    t = time.time()
    subprocess.run(sys.argv[1:], stdout=subprocess.DEVNULL)
    d = time.time() - t
    best = d if best is None or d < best else best
print(round(best, 3))' "$@"; }
for wh in "${RES[@]}"; do
  w=${wh%% *}; h=${wh##* }
  for b in "${BOUNCES[@]}"; do
    sed -e "s/^const width = .*/const width = $w/" \
        -e "s/^const height = .*/const height = $h/" \
        -e "s/^const max_depth = .*/const max_depth = $b/" \
        /tmp/raytracer-original.gleam > $SRC
    cd $RT
    GLEAM_ZIG=$Z $G export zig-executable --out /tmp/rt-cell >/dev/null 2>&1
    s=$(timeit /tmp/rt-cell)
    echo "{\"target\":\"zig\",\"w\":$w,\"h\":$h,\"bounces\":$b,\"seconds\":$s}" >> $OUT
    $G build --target javascript >/dev/null 2>&1
    echo 'import { main } from "./raytracer.mjs"; main();' > build/dev/javascript/raytracer/run.mjs
    s=$(timeit node build/dev/javascript/raytracer/run.mjs)
    echo "{\"target\":\"node\",\"w\":$w,\"h\":$h,\"bounces\":$b,\"seconds\":$s}" >> $OUT
    $G build --target erlang >/dev/null 2>&1
    s=$(timeit erl -pa build/dev/erlang/raytracer/ebin -pa build/dev/erlang/gleam_stdlib/ebin -noshell -eval 'raytracer:main(), init:stop().')
    echo "{\"target\":\"erlang\",\"w\":$w,\"h\":$h,\"bounces\":$b,\"seconds\":$s}" >> $OUT
    echo "done $w x $h b$b" >&2
  done
done
cp /tmp/raytracer-original.gleam $SRC
echo SMALL-COMPLETE >&2
