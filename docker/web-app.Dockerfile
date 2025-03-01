# Build stage
FROM node:20.17.0-alpine AS build

# Set the working directory
WORKDIR /app

# Copy package files
COPY ../client/package*.json ./

# Install dependencies
RUN npm ci

# Copy the application code
COPY ../client/ .

# Build application
ENV NEXT_TELEMETRY_DISABLED 1
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
COPY --from=build /app/.next/static ./.next/static

# Set environment variables
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Security: non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose the port for the application
EXPOSE 3000

# Start Next.js server
CMD ["node", "server.js"]