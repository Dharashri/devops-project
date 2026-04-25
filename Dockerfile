# ─────────────────────────────────────────────
#  Dockerfile
#  Serves index.html via NGINX on port 80
# ─────────────────────────────────────────────
FROM nginx:stable-alpine

LABEL maintainer="devops-team"
LABEL description="PRT DevOps Pipeline - NGINX App"

# Remove default NGINX static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy our application HTML
COPY app/index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]

