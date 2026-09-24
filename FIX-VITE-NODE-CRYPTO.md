# Vite `node:crypto` browser-bundle fix

The live-storage server-function modules were importing Node-only modules at module scope. Because those modules are also referenced by client components through TanStack Start server functions, Vite could traverse the import graph and externalize `node:crypto` into the browser build.

The fix keeps the client-reachable server-function wrapper modules browser-safe:

- removed the module-scope `node:crypto` import from `src/lib/storage/server.ts`;
- replaced the upload-chunk SHA-256 calculation with Web Crypto (`crypto.subtle`);
- moved imports of `crypto.server`, `adapters.server`, `oauth.server`, and `cache.server` inside server-side handlers/functions;
- moved the corresponding server-only imports in `src/lib/drive/server.ts` to dynamic imports.

Node-only modules remain available to the server runtime, but they are no longer statically reachable from the browser bundle through the server-function wrappers.

A full dependency install/build could not be completed in this environment because the npm install timed out and left an incomplete `node_modules`. The source-level boundary check confirms there are no static `node:` imports in the client-reachable wrapper modules.
