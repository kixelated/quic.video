FROM oven/bun:latest

WORKDIR /app

COPY . .
RUN bun install --frozen-lockfile --production

RUN bun run astro telemetry disable
RUN bun run build

ENV HOST="0.0.0.0"
CMD [ "bun", "./dist/server/entry.mjs" ]
