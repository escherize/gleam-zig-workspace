#!/bin/zsh
# Measure the raytracer across a resolution x bounces matrix on all three
# targets. Emits JSON lines: {"target","w","h","bounces","seconds"}.
set -e
RT=/Users/bcm/dv/gleam-zig/examples/demo/raytracer
SRC=$RT/src/raytracer.gleam
G=/Users/bcm/dv/gleam-zig/gleam/target/debug/gleam
Z=/Users/bcm/dv/gleam-zig/toolchain/zig-aarch64-macos-0.16.0/zig
OUT=/tmp/rt-matrix.jsonl
: > $OUT
cp $SRC /tmp/raytracer-original.gleam

# res tiers (w h) and bounce counts
RES=("320 240" "640 480" "1280 960" "2560 1920" "3840 2880" "7680 5760")
BOUNCES=(1 2 3 5 10)
# erlang measured only up to this pixel count (a 1280x960 render is ~25 s;
# 8K would be ~15 min per cell)
ERL_MAX_PIXELS=$((1280*960))
# node measured up to 4K-ish (8K node ~ 70+ s per cell x 5 bounces)
NODE_MAX_PIXELS=$((3840*2880))

patch_src() {
  sed -e "s/^const width = .*/const width = $1/" \
      -e "s/^const height = .*/const height = $2/" \
      -e "s/^const max_depth = .*/const max_depth = $3/" \
      /tmp/raytracer-original.gleam > $SRC
}

t() { # time a command, print seconds
  local start=$(python3 -c 'import time; print(time.time())')
  "$@" > /dev/null
  python3 -c "import time; print(round(time.time() - $start, 3))"
}

for wh in "${RES[@]}"; do
  w=${wh%% *}; h=${wh##* }
  px=$((w*h))
  for b in "${BOUNCES[@]}"; do
    patch_src $w $h $b
    cd $RT
    # zig: always
    GLEAM_ZIG=$Z $G export zig-executable --out /tmp/rt-cell >/dev/null 2>&1
    s=$(t /tmp/rt-cell)
    echo "{\"target\":\"zig\",\"w\":$w,\"h\":$h,\"bounces\":$b,\"seconds\":$s}" >> $OUT
    # node
    if [ $px -le $NODE_MAX_PIXELS ]; then
      $G build --target javascript >/dev/null 2>&1
      echo 'import { main } from "./raytracer.mjs"; main();' > build/dev/javascript/raytracer/run.mjs
      s=$(t node build/dev/javascript/raytracer/run.mjs)
      echo "{\"target\":\"node\",\"w\":$w,\"h\":$h,\"bounces\":$b,\"seconds\":$s}" >> $OUT
    fi
    # erlang
    if [ $px -le $ERL_MAX_PIXELS ]; then
      $G build --target erlang >/dev/null 2>&1
      s=$(t erl -pa build/dev/erlang/*/ebin -noshell -eval 'raytracer:main(), init:stop().')
      echo "{\"target\":\"erlang\",\"w\":$w,\"h\":$h,\"bounces\":$b,\"seconds\":$s}" >> $OUT
    fi
    echo "done $w x $h b$b" >&2
  done
done
cp /tmp/raytracer-original.gleam $SRC
echo MATRIX-COMPLETE >&2
