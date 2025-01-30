FROM node:slim

WORKDIR /app

COPY . .

ENV NODE_ENV=production
RUN npm ci
RUN npm run build

ENV HOST="0.0.0.0"
CMD [ "node", "run", "./dist/server/entry.mjs" ]
