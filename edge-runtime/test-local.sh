#!/bin/bash
set -e

# Local testing script for Edge Runtime

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info "==================================================="
print_info "Building and Testing Edge Runtime Locally"
print_info "==================================================="

# Build the Docker image
print_info "Building Docker image..."
cd "$(dirname "$0")"

# Ensure functions directory exists
if [ ! -d "functions" ]; then
    print_warn "Copying functions from volumes..."
    mkdir -p functions
    cp -r ../volumes/functions/* functions/ 2>/dev/null || true
fi

docker build -t supabase-edge-runtime:local -f Dockerfile ..

# Stop existing container if running
print_info "Stopping existing container (if any)..."
docker stop edge-runtime-local 2>/dev/null || true
docker rm edge-runtime-local 2>/dev/null || true

# Run the container
print_info "Starting Edge Runtime container..."
docker run -d \
  --name edge-runtime-local \
  -p 9000:9000 \
  -e JWT_SECRET="${JWT_SECRET:-your-jwt-secret}" \
  -e ANON_KEY="${ANON_KEY:-your-anon-key}" \
  -e SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-your-service-role-key}" \
  -e REQUIRE_AUTH="${REQUIRE_AUTH:-false}" \
  supabase-edge-runtime:local

# Wait for container to be healthy
print_info "Waiting for container to be ready..."
sleep 5

# Test health endpoint
print_info "Testing health endpoint..."
if curl -f http://localhost:9000/health > /dev/null 2>&1; then
    print_info "✓ Health check passed"
else
    print_warn "✗ Health check failed"
fi

print_info "==================================================="
print_info "Edge Runtime is running locally!"
print_info "==================================================="
print_info "Health Check: http://localhost:9000/health"
print_info "Test Functions:"
print_info "  curl http://localhost:9000/hello-world"
print_info "  curl http://localhost:9000/ai-assistant"
print_info "==================================================="
print_info "View logs: docker logs -f edge-runtime-local"
print_info "Stop: docker stop edge-runtime-local"
print_info "==================================================="
