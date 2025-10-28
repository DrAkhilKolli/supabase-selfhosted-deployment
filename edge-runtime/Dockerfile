# Dockerfile for Self-Hosted Edge Functions on AWS
# Based on Supabase Edge Runtime with Deno

FROM ghcr.io/supabase/edge-runtime:v1.69.14

# Set working directory
WORKDIR /usr/services

# Copy Edge Functions
COPY ./functions /usr/services/functions

# Copy main service entry point
COPY ./main /usr/services/main

# Expose port for Edge Runtime
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:9000/health || exit 1

# Start Edge Runtime with main service
CMD ["start", "--main-service", "/usr/services/main", "-p", "9000"]
