import { readFileSync, writeFileSync } from "node:fs";

// Write the page into the first HTML response so the first paint does not wait on JavaScript.
const mod = await import("../.ssr/entry-server.js");
const htmlPath = new URL("../dist/index.html", import.meta.url);
const html = readFileSync(htmlPath, "utf8");
const markup = mod.render();
const next = html.replace('<div id="root"></div>', `<div id="root">${markup}</div>`);
if (next === html || !markup.includes("foldtint")) {
  throw new Error("Prerender did not write the page");
}
writeFileSync(htmlPath, next);
