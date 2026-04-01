import fs from "node:fs";
import path from "node:path";

const projectDir = process.cwd();
const standaloneDir = path.join(projectDir, ".next", "standalone");

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
  path.join(projectDir, ".next", "static"),
  path.join(standaloneDir, ".next", "static")
);

copyIfExists(path.join(projectDir, "public"), path.join(standaloneDir, "public"));
