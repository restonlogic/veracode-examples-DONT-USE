ARG ARCH=amd64
FROM --platform=linux/${ARCH} node:alpine

COPY --chmod=777 /app/package.json /app/package.json
COPY --chmod=777 /app/server.js /app/server.js
COPY --chmod=777 /app/public /app/public

RUN npm install --prefix /app

EXPOSE 5000

STOPSIGNAL SIGQUIT

CMD ["npm", "start", "--prefix", "/app"]