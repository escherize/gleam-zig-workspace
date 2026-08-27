#!/bin/zsh
# Autoresearch-style bench runner: build a benchmark at its published size
# in ReleaseFast and report user CPU seconds (best of N).
# usage: bench.sh <file.gleam> [sed-patch-expr] [runs]
set -e
SRC=$1
PATCH=$2
RUNS=${3:-3}
W=/Users/bcm/dv/gleam-zig/examples/_run
G=/Users/bcm/dv/gleam-zig/gleam/target/debug/gleam
Z=/Users/bcm/dv/gleam-zig/toolchain/zig-aarch64-macos-0.16.0/zig

cp "$SRC" /tmp/bench-original.gleam
if [[ -n "$PATCH" ]]; then sed -i '' "$PATCH" "$SRC"; fi
# Restore the patched source, then remove what this run created. A benchmark
# leaves no binaries or temp copies behind.
trap 'cp /tmp/bench-original.gleam "$SRC"; rm -f /tmp/bench-original.gleam /tmp/bench-bin' EXIT

cp "$SRC" $W/src/mainmod.gleam
cd $W
GLEAM_ZIG=$Z $G export zig-executable --out /tmp/bench-bin >/dev/null 2>&1

best_user=""
for i in $(seq 1 $RUNS); do
  line=$(/usr/bin/time -l /tmp/bench-bin 2>&1 >/dev/null | grep "user")
  user=$(echo "$line" | awk '/user/ {print $3}')
  if [[ -z "$best_user" ]] || python3 -c "import sys; sys.exit(0 if float('$user') < float('$best_user') else 1)"; then
    best_user=$user
  fi
done
echo "user_best=$best_user"
