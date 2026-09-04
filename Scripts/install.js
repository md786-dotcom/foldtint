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

function copyBinary(source, dest) {
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(source, dest);
  fs.chmodSync(dest, 0o755);
}

if (process.platform !== "darwin") {
  fail("this package works on macOS only.");
}

const vendor = path.join(root, "vendor", "foldtint");
const prebuild = path.join(
  root,
  "prebuilds",
  `darwin-${process.arch}`,
  "foldtint"
);

if (fs.existsSync(prebuild)) {
  copyBinary(prebuild, vendor);
  process.exit(0);
}

try {
  execFileSync("swift", ["build", "-c", "release", "--product", "foldtint"], {
    cwd: root,
    stdio: "inherit",
  });
} catch (error) {
  fail("the Swift build failed. Install Xcode Command Line Tools and retry.");
}

const built = findBuiltBinary();
if (built === "") {
  fail("the Swift compiler did not write the foldtint binary.");
}

copyBinary(built, vendor);
