# Build stage
FROM node:20.17.0-alpine AS build

# Set the working directory
WORKDIR /app

# Copy package files
COPY ../client/package*.json ./

# Install dependencies
RUN npm install

# Copy the application code
COPY ../client/ .

# Build the Next.js application
RUN npm run build

# Production stage
FROM node:20.17.0-alpine as Runtime

# Set the working directory
WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=build /app/package.json ./
COPY --from=build /app/next.config.mjs ./next.config.mjs
COPY --from=build /app/public ./public
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./


# Expose the port the application will run on
EXPOSE 3000

# Start the Next.js server
CMD ["node", "server.js"]