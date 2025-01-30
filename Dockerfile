FROM node:slim

WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json .
RUN npm ci

COPY . .
RUN npm run build

ENV HOST="0.0.0.0"
CMD [ "node", "./dist/server/entry.mjs" ]
