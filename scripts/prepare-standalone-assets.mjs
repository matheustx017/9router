import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const projectDir = process.cwd();

let distDir = ".next";
try {
  const configPath = path.join(projectDir, "next.config.mjs");
  const config = await import(pathToFileURL(configPath).href);
  const cfg = config.default || config;
  if (cfg.distDir) distDir = cfg.distDir;
} catch { /* fallback to .next */ }

const standaloneDir = path.join(projectDir, distDir, "standalone");
const envFiles = [
  ".env",
  ".env.local",
  ".env.production",
  ".env.production.local",
];

function ensureExists(targetPath, label) {
  if (!fs.existsSync(targetPath)) {
    throw new Error(`${label} not found: ${targetPath}`);
  }
}

function copyIfExists(sourcePath, destinationPath) {
  if (!fs.existsSync(sourcePath)) {
    return;
  }

  fs.mkdirSync(path.dirname(destinationPath), { recursive: true });
  fs.cpSync(sourcePath, destinationPath, { recursive: true, force: true });
  console.log(`Copied ${sourcePath} -> ${destinationPath}`);
}

ensureExists(standaloneDir, "Standalone build output");

copyIfExists(
  path.join(projectDir, distDir, "static"),
  path.join(standaloneDir, distDir, "static")
);

copyIfExists(path.join(projectDir, "public"), path.join(standaloneDir, "public"));
copyIfExists(path.join(projectDir, "src", "mitm"), path.join(standaloneDir, "src", "mitm"));

for (const envFile of envFiles) {
  copyIfExists(path.join(projectDir, envFile), path.join(standaloneDir, envFile));
}
