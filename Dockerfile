# CloudFuse — production image (self-hosted, node-server target)
# Build:  docker build -t cloudfuse .
# Run:    docker run -p 7010:7010 --env-file .env cloudfuse
# (or use docker-compose.yml, which also provisions Postgres)

FROM node:22-slim AS build
WORKDIR /app

# Install deps first so this layer caches across source-only changes.
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY . .

# NITRO_PRESET pinned explicitly: VERCEL is unset in this image, but pinning
# avoids ever silently building the wrong target.
ENV NITRO_PRESET=node-server
# Build needs *some* DATABASE_URL to run db:migrate against (the "build"
# script runs `vite build && npm run db:migrate`). Point it at the compose
# Postgres service; override at build time (--build-arg) for other setups.
ARG DATABASE_URL=postgres://cloudfuse:cloudfuse@db:5432/cloudfuse
ENV DATABASE_URL=${DATABASE_URL}
RUN npm run build

# ── Runtime stage — no dev deps, no source, no build tooling ────────────────
FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=7010
ENV HOST=0.0.0.0

RUN addgroup --system --gid 1001 cloudfuse \
  && adduser --system --uid 1001 --gid 1001 cloudfuse

COPY --from=build --chown=cloudfuse:cloudfuse /app/.output ./.output
COPY --from=build --chown=cloudfuse:cloudfuse /app/scripts/start-prod.mjs ./scripts/start-prod.mjs
COPY --from=build --chown=cloudfuse:cloudfuse /app/package.json ./package.json
COPY --from=build /app/node_modules/dotenv ./node_modules/dotenv

USER cloudfuse
EXPOSE 7010

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+ (process.env.PORT||7010) +'/api/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"

CMD ["node", "scripts/start-prod.mjs"]
