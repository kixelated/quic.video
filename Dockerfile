FROM oven/bun:latest

WORKDIR /app

COPY . .

ENV NODE_ENV=production
RUN bun install --frozen-lockfile --production
RUN bun pack

ENV HOST="0.0.0.0"
CMD [ "bun", "run", "./dist/server/entry.mjs" ]
