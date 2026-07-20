FROM node:26-alpine@sha256:e88a35be04478413b7c71c455cd9865de9b9360e1f43456be5951032d7ac1a66

RUN apk add --no-cache openssl=3.5.7-r0 \
  && rm -f /var/log/apk.log

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
  && rm -rf /root/.npm /root/.cache /tmp/node-compile-cache

COPY prisma ./prisma
RUN ./node_modules/.bin/prisma generate \
  && rm -rf /root/.npm /root/.cache /tmp/node-compile-cache

COPY dist-protected ./dist
COPY locales ./locales
COPY artifact-manifest.json ./artifact-manifest.json
COPY scripts/entrypoint.sh ./entrypoint.sh
COPY scripts/verify-baseline-target.js ./scripts/verify-baseline-target.js
COPY scripts/snapshot-baseline-data.js ./scripts/snapshot-baseline-data.js
COPY scripts/snapshot-redis-data.js ./scripts/snapshot-redis-data.js
COPY scripts/verify-pb-idle.js ./scripts/verify-pb-idle.js

RUN chmod 0755 ./entrypoint.sh \
  && mkdir -p /app/logs \
  && chown node:node /app/logs \
  && chmod 0750 /app/logs

ENV NODE_ENV=production \
  BUBLIK_HEALTH_FILE=/tmp/bublik-health.json \
  BUBLIK_HEALTH_MAX_AGE_MS=75000

ARG BUBLIK_DISTRIBUTION_REVISION="local-build"
ARG BUBLIK_RELEASE_REVISION="0000000000000000000000000000000000000000"
ARG BUBLIK_RELEASE_CREATED="1970-01-01T00:00:00.000Z"
ARG BUBLIK_RELEASE_VERSION="0.0.0-local"
ARG BUBLIK_RELEASE_SOURCE="https://github.com/NaveLIL/bublik-ts"
ARG BUBLIK_RELEASE_SOURCE_TREE="0000000000000000000000000000000000000000"

LABEL org.opencontainers.image.title="Bublik Bot" \
  org.opencontainers.image.description="Protected runtime distribution of the Bublik Discord bot" \
  org.opencontainers.image.revision="${BUBLIK_DISTRIBUTION_REVISION}" \
  org.opencontainers.image.created="${BUBLIK_RELEASE_CREATED}" \
  org.opencontainers.image.version="${BUBLIK_RELEASE_VERSION}" \
  org.opencontainers.image.source="${BUBLIK_RELEASE_SOURCE}" \
  org.opencontainers.image.base.name="docker.io/library/node:24-alpine" \
  org.opencontainers.image.base.digest="sha256:a0b9bf06e4e6193cf7a0f58816cc935ff8c2a908f81e6f1a95432d679c54fbfd" \
  io.bublik.release.source-revision="${BUBLIK_RELEASE_REVISION}" \
  io.bublik.release.source-tree="${BUBLIK_RELEASE_SOURCE_TREE}"

HEALTHCHECK --interval=15s --timeout=5s --start-period=60s --retries=3 \
  CMD ["node", "dist/core/HealthMarker.js", "--check"]

USER node

ENTRYPOINT ["./entrypoint.sh"]
