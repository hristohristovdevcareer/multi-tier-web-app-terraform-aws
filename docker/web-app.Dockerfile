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

RUN npm run build

# Production stage
FROM node:20.17.0-alpine as Runtime

# Install AWS CLI and CA certificates for SSL handling
RUN apk add --no-cache aws-cli ca-certificates bash curl

# Set the working directory
WORKDIR /app

# Create certificate directory and set the env var to point to it
RUN mkdir -p /app/certs
ENV NODE_EXTRA_CA_CERTS=/app/certs/internal-ca.crt
ENV PROJECT_NAME=${PROJECT_NAME}
ENV AWS_REGION=${AWS_REGION}

# Copy only the necessary files from the build stage
COPY --from=build /app/package.json ./
COPY --from=build /app/next.config.mjs ./next.config.mjs
COPY --from=build /app/public ./public
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static

# Create certificate fetching script with fixed location
RUN echo '#!/bin/bash' > /app/entrypoint.sh && \
    echo 'if [ -n "${PROJECT_NAME}" ] && [ -n "${AWS_REGION}" ]; then' >> /app/entrypoint.sh && \
    echo '  echo "Fetching SSL certificate from SSM Parameter Store..."' >> /app/entrypoint.sh && \
    echo '  CERT_VALUE=$(aws ssm get-parameter --name "/${PROJECT_NAME}/internal-certificate" --with-decryption --query "Parameter.Value" --output text --region ${AWS_REGION})' >> /app/entrypoint.sh && \
    echo '  if [ $? -eq 0 ]; then' >> /app/entrypoint.sh && \
    echo '    echo "Certificate retrieved successfully"' >> /app/entrypoint.sh && \
    echo '    echo "$CERT_VALUE" > $NODE_EXTRA_CA_CERTS' >> /app/entrypoint.sh && \
    echo '    echo "Certificate saved to $NODE_EXTRA_CA_CERTS"' >> /app/entrypoint.sh && \
    echo '  else' >> /app/entrypoint.sh && \
    echo '    echo "Failed to retrieve certificate, continuing without it"' >> /app/entrypoint.sh && \
    echo '  fi' >> /app/entrypoint.sh && \
    echo 'else' >> /app/entrypoint.sh && \
    echo '  echo "PROJECT_NAME or AWS_REGION not set, skipping certificate installation"' >> /app/entrypoint.sh && \
    echo 'fi' >> /app/entrypoint.sh && \
    echo '' >> /app/entrypoint.sh && \
    echo 'exec "$@"' >> /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

# Set environment variables
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
ENV NEXT_PUBLIC_SERVER_URL ${NEXT_PUBLIC_SERVER_URL}

# Security: non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose the port for the application
EXPOSE 3000

# Use our entrypoint script to install the certificate before starting the app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["node", "server.js"]