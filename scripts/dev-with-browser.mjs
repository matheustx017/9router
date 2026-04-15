/**
 * Runs `next dev` and opens the default browser once (dev server needs a moment to listen).
 */
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";
import open from "open";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const nextBin = join(root, "node_modules", "next", "dist", "bin", "next");
const port = process.env.DEV_PORT || "20129";
const url = `http://localhost:${port}`;

const child = spawn(process.execPath, [nextBin, "dev", "--webpack", "--port", port], {
  stdio: "inherit",
  cwd: root,
  env: { ...process.env },
});

let opened = false;
function tryOpen() {
  if (opened) return;
  opened = true;
  open(url).catch(() => {});
}

setTimeout(tryOpen, 2000);

child.on("exit", (code) => {
  process.exit(code ?? 0);
});

process.on("SIGINT", () => {
  child.kill("SIGINT");
});
process.on("SIGTERM", () => {
  child.kill("SIGTERM");
});
