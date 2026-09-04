#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

fail() {
  echo "quality: $1" >&2
  exit 1
}

echo "quality: tests and coverage"
swift test --enable-code-coverage >/tmp/foldtint-test.log
bin=".build/arm64-apple-macosx/debug"
prof="$bin/codecov/default.profdata"
exe="$bin/foldtintPackageTests.xctest/Contents/MacOS/foldtintPackageTests"
report="$(xcrun llvm-cov report "$exe" -instr-profile="$prof" -ignore-filename-regex='.build|Tests|swift-argument-parser')"
echo "$report"
cover="$(echo "$report" | awk '/^TOTAL/{print $(NF-3)}' | tr -d '%')"
python3 - "$cover" <<'PY'
import sys
cover = float(sys.argv[1])
if cover < 85.0:
    raise SystemExit(f"coverage {cover}% is below 85%")
print(f"coverage {cover}%")
PY

echo "quality: Any ban"
if rg -n '\bAny\b|\bAnyObject\b|\bunknown\b' Sources; then
  fail "Any, AnyObject, or unknown is present"
fi

echo "quality: file length"
python3 - <<'PY'
import pathlib
root = pathlib.Path("Sources")
for path in root.rglob("*.swift"):
    lines = sum(1 for _ in path.open())
    if lines >= 500:
        raise SystemExit(f"{path} has {lines} lines")
print("file length ok")
PY

echo "quality: SwiftLint"
swiftlint lint --strict Sources Tests

echo "quality: Halstead and CRAP"
python3 Scripts/metrics.py \
  --sources Sources \
  --cov-json /tmp/foldtint-cov.json \
  --llvm-cov-exe "$exe" \
  --llvm-prof "$prof"

echo "quality: mutation sample"
python3 Scripts/mutate.py

echo "quality: ok"
