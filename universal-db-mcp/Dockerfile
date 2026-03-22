FROM node:20-alpine

RUN npm install -g universal-db-mcp

ENV MODE=http
ENV HTTP_PORT=8088

EXPOSE 8088

ENTRYPOINT ["universal-db-mcp"]
