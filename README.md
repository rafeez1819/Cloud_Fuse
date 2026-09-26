# CloudFuse

<img width="1913" height="915" alt="image" src="https://github.com/user-attachments/assets/3d62d90f-f3de-40ac-ad9b-3d23f7b12b5c" />


A unified virtual drive: sign in once, and Google Drive, OneDrive, Dropbox and
S3 show up as one filesystem. A policy engine decides where each file is
placed (type, size, free capacity) — it can also stripe a large file across
several backends.

**Control plane only.** CloudFuse does not currently copy file payloads
through its own servers to real Google/Microsoft/Dropbox/S3 accounts. It
maintains identity, hash, placement and policy for each file, and treats each
connected "drive" as a storage backend the placement engine can route to.
Real per-provider file transfer (upload/download bytes to the actual Google
Drive / OneDrive / Dropbox / S3 API) is not yet wired — see
[What's real vs. simulated](#whats-real-vs-simulated) below.

## Quick start (local, no setup)

```bash
npm install
npm run dev
```

Open **http://localhost:7010**. With no `DATABASE_URL` set, data lives in an
embedded in-memory Postgres (PGlite) — perfect for trying the UI, but it
resets every time you restart the process. Auth defaults to a single dev user
with no real sign-in until you configure a provider (below).

## Running for real (production)

### 1. Configure environment

```bash
cp .env.example .env
```

Fill in at minimum:
- `DATABASE_URL` — a real Postgres (self-hosted, Neon, RDS, etc.). **Required
  for production** — the PGlite fallback is dev/preview only and loses all
  data on every restart.
- `BETTER_AUTH_URL` — your public origin, e.g. `https://drive.example.com`.
- `BETTER_AUTH_SECRET` — `openssl rand -hex 32`.
- At least one OAuth provider (`GOOGLE_CLIENT_ID`/`SECRET`,
  `MICROSOFT_CLIENT_ID`/`SECRET`, and/or `DROPBOX_CLIENT_ID`/`SECRET`) — see
  the comments in `.env.example` for exactly where to register each app and
  which redirect URI to set. **Microsoft is the "sign in and connect
  OneDrive" entry point** — it's a Microsoft Entra ID (Azure AD) app, which
  covers both personal Microsoft/OneDrive accounts and work/school 365
  accounts (controlled by `MICROSOFT_TENANT_ID`).

### 2a. Docker (recommended)

```bash
docker compose up --build
```

This builds the app, starts a Postgres container, runs migrations, and
serves CloudFuse on **http://localhost:7010**. `docker-compose.yml` reads
`BETTER_AUTH_SECRET` (and the OAuth vars) from your shell/`.env` — Compose
auto-loads a `.env` file in the project root.

### 2b. Bare Node (no Docker)

```bash
npm ci
npm run build     # builds a standalone Node server (node-server preset)
npm start         # runs it on PORT (default 7010)
```

Point `DATABASE_URL` at a real Postgres you provision yourself before
`npm run build` — the build step also runs pending migrations against it.

### Health check

`GET /api/health` returns `200 {"status":"ok","db":"neon"}` when the app and
database are both reachable, `503` otherwise. Wired into the Docker image's
`HEALTHCHECK` already; point your load balancer / orchestrator at it too.

## Auth modes

- **`standalone`** (default, `VITE_AUTH_MODE=standalone`): real, direct OAuth
  to Google / Microsoft / Dropbox, no third party broker. This is the mode
  for running CloudFuse yourself.
- **`broker`**: the original Grok-platform federated sign-in (Google/X via
  Grok's own auth broker). Only relevant if you redeploy this app back onto
  the Grok app-builder platform — leave `standalone` otherwise.

`VITE_AUTH_MODE` and `VITE_AUTH_ENABLED` are baked in at **build time**
(they're client-bundle constants), so changing them requires a rebuild, not
just a server restart.

## What's real vs. simulated

| Area | Status |
|---|---|
| Sign-in (Google / Microsoft / Dropbox OAuth) | **Real** — standard OAuth against each provider's own console |
| Per-user workspace, folders, file metadata, audit log | **Real** — persisted in Postgres |
| Placement policy engine (`src/lib/drive/routing.ts`) | **Real logic**, run against real or simulated connection capacity/usage |
| Linking multiple accounts of the same provider | **Real** — every "connect" adds a distinct account, no limit per provider |
| "Connect" a provider **without** a local folder path | **Simulated** — creates a database row, no real cloud account behind it |
| "Connect" a provider **with** a real synced folder path (Google Drive for Desktop, OneDrive, Dropbox client) | **Real** — no OAuth at all. Uploads write actual bytes into that folder (striped across multiple real folders for large files, reassembled byte-exact on download); that provider's own desktop app does the real cloud sync from there. See `npm run test:local-folder` for a self-contained proof (writes/reads/hash-verifies a striped 9 MB file across two folders) |
| Actual OAuth-based file transfer (Drive/Graph/Dropbox/S3 *APIs*, not a synced folder) | **Not implemented** — a separate, larger project (real per-provider adapters, resumable uploads, quota APIs) from what's in this repo today |
| Files ≤ ~1.5 MB uploaded to a connection with **no** local path | Stored inline (base64) in Postgres, as before |
| Files > ~1.5 MB uploaded to a connection with **no** local path | Still a demo placeholder on download — only local-path-backed connections get real bytes right now |

Turning the remaining simulated connections into full OAuth-API integrations
means, per provider: file-access scopes beyond sign-in, the provider's
list/upload/download API, resumable/chunked upload for large files, and
either a background job queue or streaming proxy for transfers. Happy to
scope that next if/when you want cloud accounts that *aren't* already synced
to a local folder.

## Real storage via a local synced folder

No OAuth, no API keys, no Cloud Console. If you already have Google Drive
for Desktop, OneDrive, or the Dropbox client signed in and syncing on this
machine, point a connection at that folder (Settings → Connected clouds →
"Link another … account" → paste the folder path, e.g. `G:\My Drive`) and
uploads become real files there — inside a `CloudFuse/` subfolder — which
that provider's own client then syncs to the actual cloud, exactly as if
you'd dragged the file in yourself. Leave the path blank for a demo
connection instead.

## Ports & env reference

See `.env.example` for the full list with inline explanations. Everything
defaults sanely for local dev; production requires at minimum `DATABASE_URL`,
`BETTER_AUTH_URL`, `BETTER_AUTH_SECRET`, and one OAuth provider.
