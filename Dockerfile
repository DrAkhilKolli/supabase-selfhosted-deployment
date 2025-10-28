# Supabase Self-Hosted Custom Docker Image
# This creates a pre-configured Supabase setup for cloud deployment

FROM alpine:latest

# Install dependencies
RUN apk add --no-cache \
    docker \
    docker-compose \
    bash \
    curl \
    jq \
    openssl

# Create application directory
WORKDIR /app

# Copy application files
COPY docker-compose.yml .
COPY docker-compose.s3.yml .
COPY docker-compose-multi.yml .
COPY volumes/ ./volumes/
COPY deployment/ ./deployment/

# Copy configuration templates
COPY .env.template .env.template

# Copy scripts
COPY deployment/scripts/ ./scripts/
RUN chmod +x ./scripts/*.sh

# Create volumes directory
RUN mkdir -p /app/volumes/db \
    /app/volumes/storage \
    /app/volumes/logs

# Health check script
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Environment setup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000 5432 8443

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["docker-compose", "up", "-d"]