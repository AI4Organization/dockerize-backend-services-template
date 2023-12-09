# Stage 1: Install only production dependencies
# Define build arguments
ARG NODE_ENV
ARG PORT

FROM node:20.10.0-buster-slim as builder

WORKDIR /app

# Update npm to specific version
RUN npm install -g npm@10.2.5

COPY package*.json ./

RUN npm ci --omit=dev

# Stage 2: Compile our application from TypeScript
FROM node:20.10.0-buster-slim as compiler

WORKDIR /app

# Update npm to specific version
RUN npm install -g npm@10.2.5

COPY package*.json ./

# This could be optimized by copying the node_modules from the builder to the compiler stage.
COPY --from=builder /app/node_modules ./node_modules

COPY . .

RUN npm run build

# Stage 3: Create the production image
FROM node:20.10.0-buster-slim

WORKDIR /app

# Update npm to specific version
RUN npm install -g npm@10.2.5

COPY package*.json ./

# Set environment variables using build arguments
ENV NODE_ENV=${NODE_ENV} \
    PORT=${PORT}

# Copy only necessary files from the builder and compiler stages
COPY --from=builder /app/node_modules ./node_modules
COPY --from=compiler /app/dist ./dist

# Expose the port the app runs on
EXPOSE ${PORT}

CMD ["node", "dist/server.js"]
