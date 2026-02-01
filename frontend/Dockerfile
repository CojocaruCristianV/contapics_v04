# =======================
# Stage 1: Build frontend
# =======================
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build production assets
RUN npm run build

# ===========================
# Stage 2: Serve with nginx
# ===========================
FROM nginx:1.25-alpine

# Remove default nginx config (optional)
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built frontend
COPY --from=builder /app/dist /usr/share/nginx/html

# Inject BACKEND_URL at build time
ARG BACKEND_URL
RUN echo "window._env_ = { BACKEND_URL: \"${BACKEND_URL}\" };" \
    > /usr/share/nginx/html/config.js

# Expose port 80
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# Use default nginx command
CMD ["nginx", "-g", "daemon off;"]
