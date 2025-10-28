#!/bin/bash
# Build and test the Supabase Docker image locally

set -e

IMAGE_NAME="supabase-selfhosted"
TAG="latest"

echo "🏗️ Building Supabase Self-Hosted Docker Image..."

# Build the image
docker build -t "${IMAGE_NAME}:${TAG}" .

echo "✅ Image built successfully: ${IMAGE_NAME}:${TAG}"

# Test the image
echo "🧪 Testing the image..."
docker run --rm -d \
    --name supabase-test \
    -p 8000:8000 \
    -p 5432:5432 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    "${IMAGE_NAME}:${TAG}"

echo "⏳ Waiting for services to start..."
sleep 30

# Check health
if docker exec supabase-test /healthcheck.sh; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed!"
    docker logs supabase-test
    docker stop supabase-test
    exit 1
fi

# Cleanup
docker stop supabase-test
echo "🧹 Test cleanup completed"

echo "🎉 Image is ready for deployment!"
echo "To run: docker run -d -p 8000:8000 -p 5432:5432 ${IMAGE_NAME}:${TAG}"