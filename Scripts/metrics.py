#!/usr/bin/env python3
"""Compute cyclomatic, Halstead difficulty, and CRAP for Swift sources."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

DECISIONS = re.compile(
    r"\b(if|guard|while|for|catch|case|switch)\b|&&|\|\||\?"
)
OPERATORS = re.compile(
    r"==|!=|<=|>=|\+=|-=|\*=|/=|&&|\|\||->|[!=+\-*/%<>?:.(),\[\]{}]"
)
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    lines = []
    for line in text.splitlines():
        if "//" in line:
            line = line[: line.index("//")]
        lines.append(line)
    return "\n".join(lines)


def functions(text: str) -> list[tuple[str, str]]:
    found: list[tuple[str, str]] = []
    pattern = re.compile(
        r"(?:func|init)\s+([A-Za-z_][A-Za-z0-9_]*)?\s*\([^)]*\)[^{]*\{",
        re.M,
    )
    for match in pattern.finditer(text):
        name = match.group(1) or "init"
        start = match.end() - 1
        body, end = take_block(text, start)
        found.append((name, body))
    return found


def take_block(text: str, start: int) -> tuple[str, int]:
    depth = 0
    index = start
    while index < len(text):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start : index + 1], index + 1
        index += 1
    return text[start:], len(text)


def cyclomatic(body: str) -> int:
    return 1 + len(DECISIONS.findall(body))


def cognitive(body: str) -> int:
    score = 0
    nest = 0
    tokens = re.findall(r"\b(if|guard|for|while|switch|catch)\b|\{|\}", body)
    for token in tokens:
        if token == "{":
            nest += 1
        elif token == "}":
            nest = max(0, nest - 1)
        else:
            score += 1 + max(0, nest - 1)
    return score


def halstead_difficulty(body: str) -> float:
    ops = OPERATORS.findall(body)
    operands = [m for m in IDENT.findall(body) if m not in {
        "if", "else", "guard", "func", "return", "let", "var", "try", "catch",
        "switch", "case", "for", "while", "true", "false", "nil", "Self", "self",
        "throw", "throws", "static", "enum", "struct", "class", "import",
    }]
    n1 = len(set(ops)) or 1
    n2 = len(set(operands)) or 1
    N2 = len(operands) or 1
    return (n1 / 2.0) * (N2 / n2)


def file_coverage(export: dict, path: str) -> float:
    for data in export.get("data", []):
        for file_data in data.get("files", []):
            filename = file_data.get("filename", "")
            if filename.endswith(path) or path in filename:
                summary = file_data.get("summary", {}).get("lines", {})
                count = summary.get("count", 0)
                covered = summary.get("covered", 0)
                if count == 0:
                    return 1.0
                return covered / count
    return 1.0


def crap(cc: int, cov: float) -> float:
    return (cc ** 2) * ((1.0 - cov) ** 3) + cc


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sources", required=True)
    parser.add_argument("--llvm-cov-exe", required=True)
    parser.add_argument("--llvm-prof", required=True)
    parser.add_argument("--cov-json", required=True)
    args = parser.parse_args()
    subprocess.run(
        [
            "xcrun",
            "llvm-cov",
            "export",
            args.llvm_cov_exe,
            f"-instr-profile={args.llvm_prof}",
            "-ignore-filename-regex=.build|Tests|swift-argument-parser",
        ],
        check=True,
        stdout=open(args.cov_json, "w"),
    )
    export = json.loads(Path(args.cov_json).read_text())
    failures: list[str] = []
    for path in sorted(Path(args.sources).rglob("*.swift")):
        text = strip_comments(path.read_text())
        cov = file_coverage(export, str(path))
        for name, body in functions(text):
            cc = cyclomatic(body)
            cog = cognitive(body)
            diff = halstead_difficulty(body)
            score = crap(cc, cov)
            if cc >= 22:
                failures.append(f"{path}:{name} cyclomatic {cc}")
            if cog >= 22:
                failures.append(f"{path}:{name} cognitive {cog}")
            if diff >= 80:
                failures.append(f"{path}:{name} Halstead difficulty {diff:.1f}")
            if score >= 25:
                failures.append(f"{path}:{name} CRAP {score:.1f} (cc={cc}, cov={cov:.2f})")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("metrics ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
