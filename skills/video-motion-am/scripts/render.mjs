// Grava ad.html quadro a quadro via Chrome DevTools Protocol.
// uso: node render.mjs <pagina.html absoluto> <pasta-frames> [fps] [tempos,separados,por,virgula]
// A página define window.render(t), window.DURATION e (opcional) window.HEIGHT (padrão 1920).
import { spawn } from "node:child_process";
import { writeFileSync, mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
const [, , page, outDir, fpsArg = "30", only] = process.argv;
const fps = Number(fpsArg), PORT = 9339;
mkdirSync(outDir, { recursive: true });
const profile = mkdtempSync(join(tmpdir(), "render-prof-"));
const chrome = spawn("chromium", ["--headless=new", `--remote-debugging-port=${PORT}`, "--hide-scrollbars",
  "--disable-gpu", "--force-color-profile=srgb", `--user-data-dir=${profile}`, "--allow-file-access-from-files", "about:blank"], { stdio: "ignore" });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const tgt = targets.find((t) => t.type === "page");
const ws = new WebSocket(tgt.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener("open", r));
let id = 0; const pending = new Map();
ws.addEventListener("message", (ev) => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } });
const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending.set(i, (m) => m.error ? rej(new Error(method + ": " + m.error.message)) : res(m.result)); ws.send(JSON.stringify({ id: i, method, params })); });
const evaluate = async (expr) => (await send("Runtime.evaluate", { expression: expr, awaitPromise: true, returnByValue: true })).result.value;
await send("Emulation.setDeviceMetricsOverride", { width: 1080, height: 1920, deviceScaleFactor: 1, mobile: false });
await send("Page.enable");
await send("Page.navigate", { url: "file://" + page });
for (let i = 0; i < 100; i++) { if (await evaluate("document.readyState === 'complete' && typeof render === 'function'")) break; await sleep(100); }
await evaluate("document.fonts.ready.then(() => Promise.all([...document.images].map(i => i.decode().catch(() => {})))).then(() => document.fonts.check('800 40px Inter'))").then((ok) => console.log("Inter carregada:", ok));
const height = await evaluate("window.HEIGHT || 1920");
await send("Emulation.setDeviceMetricsOverride", { width: 1080, height, deviceScaleFactor: 1, mobile: false });
const duration = await evaluate("DURATION");
const times = only !== undefined ? only.split(",").map(Number) : Array.from({ length: Math.round(duration * fps) }, (_, i) => i / fps);
for (let i = 0; i < times.length; i++) {
  await evaluate(`render(${times[i]})`);
  const { data } = await send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  const name = only !== undefined ? `t${times[i]}.png` : `f${String(i).padStart(5, "0")}.png`;
  writeFileSync(`${outDir}/${name}`, Buffer.from(data, "base64"));
  if (i % 150 === 0) console.log(`${i}/${times.length}`);
}
ws.close(); chrome.kill();
await sleep(300); rmSync(profile, { recursive: true, force: true });
console.log("ok", times.length, "quadros");
