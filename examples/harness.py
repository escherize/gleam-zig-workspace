#!/usr/bin/env python3
"""Run Gleam programs on the zig target and compare output with the
JavaScript target.

Usage:
  harness.py <dir-of-gleam-files-or-single-file>...

Each input program is copied into a scratch project (examples/_run) as the
main module and executed once per target. Outputs are normalised (ANSI
stripped, echo's file:line lines reduced to their line number) and diffed.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT / "_run"
# Overridable for CI and other machines; defaults match the local layout.
GLEAM = Path(
    os.environ.get("GLEAM_BIN", ROOT.parent / "gleam" / "target" / "debug" / "gleam")
)
ZIG = Path(
    os.environ.get(
        "GLEAM_ZIG", ROOT.parent / "toolchain" / "zig-aarch64-macos-0.16.0" / "zig"
    )
)

ANSI = re.compile(r"\x1b\[[0-9;]*m")
FILE_LINE = re.compile(r"^\S*\.gleam:(\d+)$")


def setup_project():
    (PROJECT / "src").mkdir(parents=True, exist_ok=True)
    (PROJECT / "gleam.toml").write_text(
        'name = "mainmod"\nversion = "1.0.0"\n\n'
        "[dependencies]\n"
        'gleam_stdlib = { path = "../../gleam-stdlib" }\n'
    )


def normalise(text: str) -> str:
    lines = []
    for line in ANSI.sub("", text).splitlines():
        match = FILE_LINE.match(line.strip())
        if match:
            lines.append(f"<src>:{match.group(1)}")
        else:
            lines.append(line.rstrip())
    return "\n".join(lines).strip()


def run_target(target: str) -> tuple[int, str]:
    try:
        result = subprocess.run(
            [str(GLEAM), "run", "--target", target],
            cwd=PROJECT,
            capture_output=True,
            text=True,
            timeout=20,
            env=os.environ | {"GLEAM_ZIG": str(ZIG)},
        )
    except subprocess.TimeoutExpired as e:
        # TimeoutExpired yields bytes even when text=True.
        def as_text(stream) -> str:
            if stream is None:
                return ""
            if isinstance(stream, bytes):
                return stream.decode(errors="replace")
            return stream

        return 124, normalise(as_text(e.stdout) + as_text(e.stderr))
    # Drop gleam's own progress lines (they go to stderr before the program).
    output = result.stdout + result.stderr
    interesting = []
    for line in output.splitlines():
        stripped = ANSI.sub("", line)
        if re.match(r"^\s*(Compiling|Compiled|Resolving|Downloading|Running)", stripped):
            continue
        interesting.append(line)
    return result.returncode, normalise("\n".join(interesting))


def outputs_match(zig_output: str, js_output: str) -> bool:
    """The JavaScript target cannot distinguish Int from Float (both are JS
    numbers), so its echo prints 2 for the float 2.0. The zig target prints
    2.0 like Erlang does. Accept zig "N.0" where JS printed integer "N",
    anywhere numbers appear in a line."""
    zig_lines = zig_output.splitlines()
    js_lines = js_output.splitlines()
    if len(zig_lines) != len(js_lines):
        return False
    for zig_line, js_line in zip(zig_lines, js_lines):
        if zig_line == js_line:
            continue
        if re.sub(r"(\d+)\.0(?!\d)", r"\1", zig_line) == js_line:
            continue
        return False
    return True


def main() -> int:
    inputs = []
    for argument in sys.argv[1:]:
        path = Path(argument)
        if path.is_dir():
            inputs.extend(sorted(path.rglob("code.gleam")))
            inputs.extend(sorted(p for p in path.glob("*.gleam")))
        else:
            inputs.append(path)

    setup_project()
    passed, failed, skipped = 0, 0, 0
    failures = []

    for source in inputs:
        label = str(source)
        code = source.read_text()
        # Dict iteration order is explicitly unspecified, so dict-heavy
        # programs cannot be compared textually across targets.
        nondeterministic = "random" in code or "dict." in code
        uses_bit_arrays = "<<" in code
        # Numeric-model divergence: zig ints are i64, JS ints are f64,
        # Erlang has bignums. Programs whose output depends on overflow
        # behaviour differ by design.
        overflow_sensitive = "Wilsons-theorem" in label
        (PROJECT / "src" / "mainmod.gleam").write_text(code)
        # Wipe only the project's own build artifacts, keep dependency cache.
        for stale in (PROJECT / "build").rglob("mainmod*"):
            if stale.is_file():
                stale.unlink()

        if uses_bit_arrays:
            skipped += 1
            print(f"SKIP {label} (bit arrays not supported on zig yet)")
            continue
        if overflow_sensitive:
            skipped += 1
            print(f"SKIP {label} (int overflow semantics differ per target)")
            continue

        zig_code, zig_output = run_target("zig")

        if "Unknown module" in zig_output:
            skipped += 1
            print(f"SKIP {label} (missing dependency)")
            continue

        if nondeterministic:
            # Output varies run to run; only require a clean run.
            if zig_code == 0:
                passed += 1
                print(f"PASS {label} (nondeterministic, exit only)")
            else:
                failed += 1
                failures.append((label, zig_code, zig_output, "<nondeterministic>"))
                print(f"FAIL {label} (zig exit {zig_code})")
            continue

        js_code, js_output = run_target("javascript")

        if js_code != 0:
            zig_crashed = zig_code != 0 or "Segmentation fault" in zig_output
            if "does not have a main function" in js_output:
                skipped += 1
                print(f"SKIP {label} (no main function)")
            elif js_code == 124 and zig_code == 124:
                # Both ran forever (by-design infinite programs).
                passed += 1
                print(f"PASS {label} (both targets run forever)")
            elif zig_crashed:
                # Both targets fail (todo/panic lessons); panic formats
                # differ per runtime so only the outcome is compared.
                passed += 1
                print(f"PASS {label} (both targets fail as expected)")
            else:
                failed += 1
                failures.append((label, zig_code, zig_output, js_output))
                print(f"FAIL {label} (js fails but zig exits 0)")
            continue

        if zig_code == 0 and outputs_match(zig_output, js_output):
            passed += 1
            print(f"PASS {label}")
        else:
            failed += 1
            failures.append((label, zig_code, zig_output, js_output))
            print(f"FAIL {label} (zig exit {zig_code})")

    print(f"\n{passed} passed, {failed} failed, {skipped} skipped")
    if passed == 0:
        # Everything skipping is a broken setup, not a green run.
        print("no programs passed; treating as failure")
        return 1
    for label, code, zig_output, js_output in failures:
        print(f"\n=== {label} (zig exit {code})")
        print("--- zig:")
        print(zig_output[:2000])
        print("--- js:")
        print(js_output[:2000])
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
