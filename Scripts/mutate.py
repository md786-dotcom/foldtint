#!/usr/bin/env python3
"""Apply comparison mutations in core Swift files and require tests to fail."""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = [
    ROOT / "Sources/FoldtintKit/TagCodec.swift",
    ROOT / "Sources/FoldtintKit/PathPolicy.swift",
    ROOT / "Sources/FoldtintKit/SyncEngine.swift",
    ROOT / "Sources/FoldtintKit/WatchFilter.swift",
]
PATTERN = re.compile(r"(==|!=)")


def mutants(path: Path) -> list[tuple[int, str, str]]:
    found: list[tuple[int, str, str]] = []
    for index, line in enumerate(path.read_text().splitlines()):
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("case "):
            continue
        if "==" in line or "!=" in line:
            if "==" in line:
                found.append((index, line, line.replace("==", "!=", 1)))
            elif "!=" in line:
                found.append((index, line, line.replace("!=", "==", 1)))
    return found[:1]


def run_tests() -> bool:
    result = subprocess.run(
        ["swift", "test"],
        cwd=ROOT,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode == 0


def main() -> int:
    subprocess.run(["swift", "test"], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    killed = 0
    survived = 0
    applied: list[tuple[Path, str]] = []
    try:
        for path in TARGETS:
            original = path.read_text()
            for _, old, new in mutants(path):
                if old == new:
                    continue
                path.write_text(original.replace(old, new, 1))
                applied.append((path, original))
                passed = run_tests()
                path.write_text(original)
                applied.pop()
                if passed:
                    survived += 1
                    print(f"survived: {path.name}: {old.strip()} -> {new.strip()}")
                else:
                    killed += 1
    finally:
        for path, original in applied:
            path.write_text(original)
    total = killed + survived
    if total == 0:
        print("mutation: no mutants")
        return 1
    score = 100.0 * killed / total
    print(f"mutation: killed {killed}/{total} ({score:.1f}%)")
    if score < 85.0:
        return 1
    subprocess.run(["swift", "test"], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
