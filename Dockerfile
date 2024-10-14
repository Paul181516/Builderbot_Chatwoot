# Builder Stage
FROM node:21-alpine3.18 as builder

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate
ENV PNPM_HOME=/usr/local/bin

# Copy package.json and pnpm-lock.yaml
COPY package*.json *-lock.yaml ./

# Install dependencies including TypeScript
RUN apk add --no-cache git \
    && pnpm install \
    && apk del .gyp

# Copy the rest of the application code
COPY . .

# Compile TypeScript to JavaScript
RUN pnpm tsc

# Deploy Stage
FROM node:21-alpine3.18 as deploy

WORKDIR /app

ARG PORT
ENV PORT $PORT
EXPOSE $PORT

# Copy the compiled JavaScript files and other necessary files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json /app/*-lock.yaml ./

RUN corepack enable && corepack prepare pnpm@latest --activate 
ENV PNPM_HOME=/usr/local/bin

# Clean npm cache and install production dependencies
RUN npm cache clean --force && pnpm install --production --ignore-scripts \
    && addgroup -g 1001 -S nodejs && adduser -S -u 1001 nodejs \
    && rm -rf $PNPM_HOME/.npm $PNPM_HOME/.node-gyp

# Switch to non-root user
USER nodejs

# Define the command to run the application
CMD ["node", "dist/app.js"]
