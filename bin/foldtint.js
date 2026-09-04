#!/usr/bin/env node
"use strict";

const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const vendor = path.join(root, "vendor", "foldtint");
const prebuild = path.join(
  root,
  "prebuilds",
  `darwin-${process.arch}`,
  "foldtint"
);

let binary = "";
if (fs.existsSync(vendor)) {
  binary = vendor;
} else if (fs.existsSync(prebuild)) {
  binary = prebuild;
}

if (binary === "") {
  process.stderr.write(
    "foldtint: the macOS binary is missing. Run npm install -g foldtint again.\n"
  );
  process.exit(1);
}

const child = spawn(binary, process.argv.slice(2), { stdio: "inherit" });
child.on("error", (error) => {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
});
child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code === null ? 1 : code);
});
