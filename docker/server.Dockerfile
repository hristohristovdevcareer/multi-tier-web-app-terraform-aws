FROM node:20.17.0-alpine

WORKDIR /app

COPY ./server/package*.json ./

RUN apk add --no-cache curl

RUN npm install

COPY ./server .

EXPOSE 8080

CMD ["node", "./index.js"]