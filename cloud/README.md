# 9Router Cloud Worker

Deploy your own Cloudflare Worker to access 9Router from anywhere.

## Setup

```bash
# 1. Login to Cloudflare
npm install -g wrangler
wrangler login

# 2. Install dependencies
cd app/cloud
npm install

# 3. Create KV & D1, then paste IDs into wrangler.toml
wrangler kv namespace create KV
wrangler d1 create proxy-db

# 4. Init database & deploy
wrangler d1 execute proxy-db --remote --file=./migrations/0001_init.sql
npm run deploy
```

Copy your Worker URL -> 9Router Dashboard -> **Endpoint** -> **Setup Cloud** -> paste -> **Save** -> **Enable Cloud**.

---

# Running 9Router Locally

This machine should use a single production boot flow:

- `Task Scheduler` starts [startup-9router.ps1](../startup-9router.ps1)
- `Task Scheduler` monitors with [health-check.ps1](../health-check.ps1)
- `cloudflared` runs as a Windows service
- Production serves from `.build/standalone/server.js`
- PM2 should not run in parallel for this app

## Overview

| Mode | Command | Port | Hot Reload | Requires Build | Purpose |
|---|---|---|---|---|---|
| Auto-start Production | `startup-9router.ps1` | 20128 | No | Yes | Tunnel and remote access |
| Manual Production | `npm run start` | 20128 | No | Yes | Local production verification |
| Development | `npm run dev` | 20129 | Yes | No | Editing source code |

## Mode 1: Auto-start Production

This is the mode that should power `https://9router.shadowsplay.cloud/login`.

### Components

- Scheduled task `9Router-BootStart`
- Scheduled task `9Router-HealthCheck`
- Windows service `cloudflared`
- Standalone build at `.build/standalone/server.js`

### Restart manually

```bash
PowerShell -ExecutionPolicy Bypass -File .\startup-9router.ps1
```

### Health check manually

```bash
PowerShell -ExecutionPolicy Bypass -File .\health-check.ps1
```

### Rules

- Do not auto-start the global CLI on the same port
- Do not use PM2 for this app on this machine
- Do not point production to `.next/standalone/server.js`

### Data location

```text
C:\Users\LocalServer\AppData\Roaming\9router\
```

This directory is shared by production and development flows.

## Mode 2: Manual Production

Useful when testing the current repository build before or after a change.

### Build

```bash
npm run build
```

### Start

```bash
npm run start
```

### Rebuild when

- you run `npm install`
- you update dependencies
- you change source files under `src/`

If you skip the rebuild after a dependency or source change, the app can get stuck on `Loading...` because HTML and chunk hashes stop matching.

## Mode 3: Development

Use this while editing the repository.

```bash
npm run dev
```

Then open:

```text
http://localhost:20129
```

## Quick checks

### Which port is active?

```bash
netstat -ano | findstr :20128
netstat -ano | findstr :20129
```

### Production local URL

```text
http://localhost:20128/login
```

### Tunnel URL

```text
https://9router.shadowsplay.cloud/login
```

## Updating the global CLI

The global CLI is a separate/manual path. If you update it:

```bash
npm install -g 9router@latest
```

do not auto-start it in parallel with the scheduled production flow above.
