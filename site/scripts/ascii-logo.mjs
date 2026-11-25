import { writeFileSync } from "node:fs";

const RAMP = " .:-=+*#%@";
const PURPLE = [175, 82, 222];

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

function lin(channel) {
  const c = channel / 255;
  return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

function luma(rgb) {
  return 0.2126 * lin(rgb[0]) + 0.7152 * lin(rgb[1]) + 0.0722 * lin(rgb[2]);
}

function contrast(rgb) {
  return 1.05 / (luma(rgb) + 0.05);
}

function mix(a, b, t) {
  return a.map((v, i) => v + (b[i] - v) * t);
}

function scaleToLuma(rgb, target) {
  const current = luma(rgb);
  if (current < 0.0001) return [0, 0, 0];
  let lo = 0;
  let hi = 1;
  let color = rgb;
  if (current < target) {
    for (let i = 0; i < 18; i += 1) {
      const t = (lo + hi) / 2;
      color = mix(rgb, [255, 255, 255], t);
      if (luma(color) < target) lo = t;
      else hi = t;
    }
  } else {
    for (let i = 0; i < 18; i += 1) {
      const t = (lo + hi) / 2;
      color = rgb.map((v) => v * t);
      if (luma(color) < target) lo = t;
      else hi = t;
    }
  }
  return color.map((v) => clamp(Math.round(v), 0, 255));
}

function sdRound(px, py, x, y, w, h, r) {
  const rad = Math.min(r, w / 2, h / 2);
  const qx = Math.abs(px - (x + w / 2)) - (w / 2 - rad);
  const qy = Math.abs(py - (y + h / 2)) - (h / 2 - rad);
  return Math.min(Math.max(qx, qy), 0) + Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) - rad;
}

function cover(sdf) {
  return clamp(0.5 - sdf / 0.9, 0, 1);
}

function over(dst, src, alpha) {
  if (alpha <= 0) return dst;
  if (alpha >= 1) return src;
  return dst.map((v, i) => v * (1 - alpha) + src[i] * alpha);
}

function sampleFolder(px, py) {
  let c = [255, 255, 255];
  const body = sdRound(px, py, 2, 16, 96, 56, 8);
  if (body < 1.4) {
    const t = clamp((py - 16) / 56, 0, 1);
    c = over(c, scaleToLuma(PURPLE, 0.42 - t * 0.24), cover(body));
  }
  const tab = sdRound(px, py, 2, 2, 40, 20, 6);
  if (tab < 1.3) c = over(c, scaleToLuma(PURPLE, 0.5), cover(tab));
  const lock = sdRound(px, py, 38, 40, 24, 18, 3);
  if (lock < 1.1) c = over(c, scaleToLuma([24, 10, 36], 0.04), cover(lock));
  const shackle = Math.hypot(px - 50, py - 40);
  if (py < 42 && shackle < 12 && shackle > 7) c = scaleToLuma([24, 10, 36], 0.045);
  return c.map((v) => clamp(Math.round(v), 0, 255));
}

function hex(rgb) {
  return `#${rgb.map((v) => v.toString(16).padStart(2, "0")).join("")}`;
}

function raster(colCount, samples, paint, srcW, srcH, aspect) {
  const cellW = srcW / colCount;
  const cellH = cellW * aspect;
  const rowCount = Math.round(srcH / cellH);
  const grid = [];
  for (let row = 0; row < rowCount; row += 1) {
    const line = [];
    for (let col = 0; col < colCount; col += 1) {
      let ar = 0;
      let ag = 0;
      let ab = 0;
      let ir = 0;
      let ig = 0;
      let ib = 0;
      let ink = 0;
      const n = samples * samples;
      for (let sy = 0; sy < samples; sy += 1) {
        for (let sx = 0; sx < samples; sx += 1) {
          const rgb = paint(
            (col + (sx + 0.5) / samples) * cellW,
            (row + (sy + 0.5) / samples) * cellH,
          );
          ar += rgb[0];
          ag += rgb[1];
          ab += rgb[2];
          if (luma(rgb) < 0.965) {
            ir += rgb[0];
            ig += rgb[1];
            ib += rgb[2];
            ink += 1;
          }
        }
      }
      if (ink / n < 0.55) {
        line.push({ ch: " ", color: "" });
        continue;
      }
      const avg = [ar / n, ag / n, ab / n];
      const src = [ir / ink, ig / ink, ib / ink];
      const index = Math.round((1 - luma(avg)) * (RAMP.length - 1));
      line.push({
        ch: RAMP[clamp(index, 1, RAMP.length - 1)],
        color: hex(scaleToLuma(src, Math.min(luma(src), 0.145))),
      });
    }
    grid.push(line);
  }

  let minC = colCount;
  let maxC = -1;
  let minR = rowCount;
  let maxR = -1;
  grid.forEach((line, row) => {
    line.forEach((cell, col) => {
      if (cell.ch === " ") return;
      minC = Math.min(minC, col);
      maxC = Math.max(maxC, col);
      minR = Math.min(minR, row);
      maxR = Math.max(maxR, row);
    });
  });
  const cropped = grid.slice(minR, maxR + 1).map((line) => line.slice(minC, maxC + 1));
  let html = "";
  const mono = [];
  for (const line of cropped) {
    let rowHtml = "";
    let i = 0;
    while (i < line.length) {
      if (line[i].ch === " ") {
        let j = i;
        while (j < line.length && line[j].ch === " ") j += 1;
        rowHtml += " ".repeat(j - i);
        i = j;
        continue;
      }
      let j = i + 1;
      while (j < line.length && line[j].ch === line[i].ch && line[j].color === line[i].color) j += 1;
      rowHtml += `<span style="color:${line[i].color}">${line[i].ch.repeat(j - i)}</span>`;
      i = j;
    }
    html += `${rowHtml.trimEnd()}\n`;
    mono.push(line.map((cell) => cell.ch).join("").trimEnd());
  }
  return { html: html.replace(/\n$/, ""), cols: cropped[0].length, rows: cropped.length, mono, cropped };
}

const mark = raster(10, 6, sampleFolder, 100, 76, 1.55);
if (mark.cols < 8 || mark.cols > 12 || mark.rows < 4 || mark.rows > 5) {
  throw new Error(`mark is ${mark.cols} x ${mark.rows}, want about 8-12 by 4-5`);
}
for (const line of mark.cropped) {
  for (const cell of line) {
    if (!cell.color) continue;
    const raw = cell.color.slice(1);
    const ratio = contrast([
      Number.parseInt(raw.slice(0, 2), 16),
      Number.parseInt(raw.slice(2, 4), 16),
      Number.parseInt(raw.slice(4, 6), 16),
    ]);
    if (ratio < 4.5) throw new Error(`${cell.color} contrast ${ratio.toFixed(2)} is below 4.5`);
  }
}

const ts = `export const MARK_HTML = ${JSON.stringify(mark.html)};\n`;
writeFileSync(new URL("../src/logo-ascii.ts", import.meta.url), ts);
console.log(mark.mono.join("\n"));
console.log(`\nmark ${mark.cols} x ${mark.rows}`);
