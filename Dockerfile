FROM node:14-alpine

ENV NODE_ENV=production

WORKDIR /app
RUN chown -R node:node /app

USER node

COPY --chown=node:node package.json package-lock.json ./
RUN npm ci --progress=false --no-audit --loglevel=error

COPY --chown=node:node lib/ lib/
COPY --chown=node:node index.js ./
RUN mkdir -p db conf logs

CMD ["node","index.js"]
