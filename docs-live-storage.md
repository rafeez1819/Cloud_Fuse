# CloudFuse live storage layer

This version moves CloudFuse from synthetic placement metadata to real provider-backed storage.

## What is now live

- Google Drive OAuth + Drive API listing, quota, upload, download, create folder, rename, move, delete.
- OneDrive OAuth + Microsoft Graph listing, quota, resumable upload sessions, download, create folder, rename, move, delete.
- Dropbox OAuth + Dropbox API listing, quota, upload, download, create folder, rename, move, delete.
- Amazon S3 connections with encrypted credentials, object listing, capacity accounting, upload/download/delete.
- CloudFuse chunk manifest records each physical chunk independently.
- Large uploads are split according to the existing routing plan and sent one chunk at a time from the browser.
- A local cache stores downloaded remote chunks so execution/runtime reads can avoid repeating provider transfers.
- Unified downloads use HTTP byte ranges and reassemble multiple stored chunks on demand.
- OAuth refresh tokens and access tokens are encrypted with AES-256-GCM.
- Provider sync imports existing remote files into the unified CloudFuse index.

## Provider setup

The OAuth callback URL is:

`https://YOUR_HOST/api/storage/oauth/callback/google`

`https://YOUR_HOST/api/storage/oauth/callback/onedrive`

`https://YOUR_HOST/api/storage/oauth/callback/dropbox`

Use the exact callback URL exposed by the deployment when creating each OAuth application.

Google Drive uses the full Drive scope because CloudFuse is designed to manage files already present in the user's Drive, not only files created by CloudFuse. Provider approval/verification requirements can therefore apply depending on how the OAuth application is deployed.

## Important production rule

Do not put real access tokens, refresh tokens, or S3 secrets in source control. Set `CLOUDFUSE_MASTER_KEY` in the deployment environment and let the application persist only encrypted credential material in the database.

## Execution boundary

The current live layer exposes a local HTTP file endpoint (`/api/storage/file/:id`) with byte-range support. It is intentionally not a direct filesystem mount. A future WinFSP/WebDAV/S3-compatible local mount can sit in front of this endpoint so Docker containers can consume a normal `/data` filesystem boundary without knowing which provider stores each chunk.

## Demo data

`CLOUDFUSE_DEMO_MODE=false` is the production default. When false, new workspaces are empty until a real provider is connected and synced.
