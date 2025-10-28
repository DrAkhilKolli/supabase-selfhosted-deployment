#!/bin/bash
# Push the Docker image to multiple registries

set -e

IMAGE_NAME="supabase-selfhosted"
TAG="latest"
REGISTRY_PREFIX=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--registry)
            REGISTRY_PREFIX="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$REGISTRY_PREFIX" ]; then
    echo "❌ Registry prefix required. Use -r or --registry"
    echo "Examples:"
    echo "  # Docker Hub"
    echo "  ./push-image.sh -r username"
    echo "  # AWS ECR"
    echo "  ./push-image.sh -r 123456789012.dkr.ecr.us-east-1.amazonaws.com"
    echo "  # Google Container Registry"
    echo "  ./push-image.sh -r gcr.io/project-id"
    exit 1
fi

FULL_IMAGE_NAME="${REGISTRY_PREFIX}/${IMAGE_NAME}:${TAG}"

echo "🚀 Pushing image to ${FULL_IMAGE_NAME}..."

# Tag the image
docker tag "${IMAGE_NAME}:${TAG}" "${FULL_IMAGE_NAME}"

# Push the image
docker push "${FULL_IMAGE_NAME}"

echo "✅ Image pushed successfully!"
echo "📝 To pull: docker pull ${FULL_IMAGE_NAME}"
echo "🏃 To run: docker run -d -p 8000:8000 -p 5432:5432 ${FULL_IMAGE_NAME}"