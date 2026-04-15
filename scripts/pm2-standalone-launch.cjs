/**
 * PM2 entry: runs production build, then starts Next standalone server.
 * Set PM2_SKIP_BUILD=1 in ecosystem env to skip build (fast restart).
 */
const { spawnSync } = require("child_process");
const path = require("path");

const root = path.resolve(__dirname, "..");
process.chdir(root);

if (process.env.PM2_SKIP_BUILD !== "1") {
  const npmCmd = process.platform === "win32" ? "npm.cmd" : "npm";
  const build = spawnSync(npmCmd, ["run", "build"], {
    stdio: "inherit",
    cwd: root,
    env: process.env,
  });
  if (build.status !== 0) {
    process.exit(build.status ?? 1);
  }
}

const serverJs = path.join(root, ".build", "standalone", "server.js");
const run = spawnSync(process.execPath, [serverJs], {
  stdio: "inherit",
  cwd: root,
  env: process.env,
});
process.exit(run.status ?? 1);
