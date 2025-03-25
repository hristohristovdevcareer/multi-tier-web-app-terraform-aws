FROM node:20.17.0-alpine

WORKDIR /app

COPY package*.json ./

RUN apk add --no-cache curl

RUN npm install

COPY . .

EXPOSE 8080

CMD ["node", "./index.js"]