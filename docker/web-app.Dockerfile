FROM node:20.17.0 AS build  

WORKDIR /app

COPY ../client/package*.json ./

RUN npm install

COPY ../client/ .

RUN npm run build

FROM node:20.17.0-alpine

WORKDIR /app

COPY --from=build /app/.next ./.next
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.mjs ./next.config.mjs

EXPOSE 3000

CMD ["npm", "run", "start"]
