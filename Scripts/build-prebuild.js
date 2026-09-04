"use strict";

const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");

function fail(message) {
  process.stderr.write(`foldtint: ${message}\n`);
  process.exit(1);
}

function findBuiltBinary() {
  const names = [
    path.join(root, ".build", "release", "foldtint"),
    path.join(root, ".build", `${process.arch}-apple-macosx`, "release", "foldtint"),
    path.join(root, ".build", "arm64-apple-macosx", "release", "foldtint"),
    path.join(root, ".build", "x86_64-apple-macosx", "release", "foldtint"),
  ];
  for (const file of names) {
    if (fs.existsSync(file) && fs.statSync(file).isFile()) {
      return file;
    }
  }
  return "";
}

if (process.platform !== "darwin") {
  fail("macOS is required to build this package.");
}

execFileSync("swift", ["build", "-c", "release", "--product", "foldtint"], {
  cwd: root,
  stdio: "inherit",
});

const built = findBuiltBinary();
if (built === "") {
  fail("the Swift compiler did not write the foldtint binary.");
}

const dest = path.join(root, "prebuilds", `darwin-${process.arch}`, "foldtint");
fs.mkdirSync(path.dirname(dest), { recursive: true });
fs.copyFileSync(built, dest);
fs.chmodSync(dest, 0o755);
process.stdout.write(`foldtint: wrote ${dest}\n`);
