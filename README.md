# gleam-zig workspace

Design notes, verification harness and test corpus for the
[zig compilation target fork of the Gleam compiler](https://github.com/escherize/gleam-zig).

Unofficial; not affiliated with the Gleam core team.

## Layout

| Path | What |
|---|---|
| `.notes/` | Design notes: target decision, JS-backend anatomy, Perceus memory design, implementation plan, status log, worklogs |
| `examples/harness.py` | Runs Gleam programs on both the zig and javascript targets and diffs normalised output; the zig runs are leak-checked |
| `examples/rosetta/` | 86 rosetta-code Gleam solutions used as a test corpus |
| `examples/smoke/`, `examples/bench/` | Smoke test and the list-churn RC benchmark |

Sibling checkouts expected next to this repo (see `.gitignore`):

```
gleam-zig-workspace/   this repo, checked out as gleam-zig/
├── gleam/             https://github.com/escherize/gleam-zig
├── gleam-stdlib/      https://github.com/escherize/gleam-zig-stdlib
├── simplifile/        https://github.com/escherize/gleam-zig-simplifile
├── argv/              https://github.com/escherize/gleam-zig-argv
├── envoy/             https://github.com/escherize/gleam-zig-envoy
├── gleam_native/      https://github.com/escherize/gleam-zig-native
├── toolchain/         zig 0.16.0 (below)
└── tour/              https://github.com/gleam-lang/language-tour (test input)
```

## Setup

```sh
git clone https://github.com/escherize/gleam-zig gleam
git clone https://github.com/escherize/gleam-zig-stdlib gleam-stdlib
git clone https://github.com/escherize/gleam-zig-simplifile simplifile
git clone --depth 1 https://github.com/gleam-lang/language-tour tour
mkdir toolchain && cd toolchain
curl -O https://ziglang.org/download/0.16.0/zig-aarch64-macos-0.16.0.tar.xz
tar xf zig-aarch64-macos-0.16.0.tar.xz && cd ..
cd gleam && cargo build -p gleam && cd ..   # debug build; the harness expects it
```

## Running the corpus

```sh
python3 examples/harness.py tour/src/content examples/rosetta
```

Each program runs on the zig target (leak-checked: any live allocation at
exit fails the run) and on the javascript target via node, and the
normalised outputs are compared. Current state: 129 passed, 0 failed,
20 skipped (missing hex dependencies, programs without a main function,
one int-overflow-semantics divergence).

## Licence

Apache-2.0, matching the forks this workspace supports.
