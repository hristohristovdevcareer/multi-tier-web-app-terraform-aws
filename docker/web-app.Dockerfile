# Build stage
FROM node:20.17.0-alpine AS build

# Set the working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the application code
COPY . .

# Build application
ARG NEXT_PUBLIC_SERVER_URL
ENV NEXT_PUBLIC_SERVER_URL=${NEXT_PUBLIC_SERVER_URL}
ENV NEXT_TELEMETRY_DISABLED 1

RUN npm run build && \
    npm prune --production

# Production stage
FROM node:20.17.0-alpine as Runtime

# Set the working directory
WORKDIR /app

# Create certificate directory
RUN mkdir -p /app/certs
ENV NODE_EXTRA_CA_CERTS=/app/certs/internal-ca.crt

# Copy certificate from build context (will be placed there by Terraform)
COPY certs/internal-ca.crt /app/certs/internal-ca.crt

# Copy only the necessary files from the build stage
COPY --from=build /app/package.json ./
COPY --from=build /app/next.config.mjs ./next.config.mjs
COPY --from=build /app/public ./public
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static

# Set environment variables
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
ENV NEXT_PUBLIC_SERVER_URL ${NEXT_PUBLIC_SERVER_URL}

# Security: non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app
USER nextjs

# Expose the port for the application
EXPOSE 3000

# Start the application
CMD ["node", "server.js"]