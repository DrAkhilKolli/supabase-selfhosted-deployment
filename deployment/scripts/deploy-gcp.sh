#!/bin/bash
# Deploy Supabase to Google Cloud Platform using Cloud Run

set -e

PROJECT_ID=""
SERVICE_NAME="supabase-selfhosted"
REGION="asia-south2"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE_NAME="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$PROJECT_ID" ]; then
    echo "❌ GCP Project ID required. Use -p or --project"
    exit 1
fi

IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "🚀 Deploying Supabase to Google Cloud Run..."
echo "📍 Project: ${PROJECT_ID}"
echo "🌍 Region: ${REGION}"
echo "🏷️ Service: ${SERVICE_NAME}"

# Ensure gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null; then
    echo "❌ Please authenticate with gcloud first:"
    echo "gcloud auth login"
    exit 1
fi

# Set the project
gcloud config set project "${PROJECT_ID}"

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build the image using Cloud Build
echo "🏗️ Building image with Cloud Build..."
gcloud builds submit --tag "${IMAGE_NAME}"

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
    --image "${IMAGE_NAME}" \
    --platform managed \
    --region "${REGION}" \
    --allow-unauthenticated \
    --port 8000 \
    --memory 2Gi \
    --cpu 2 \
    --min-instances 0 \
    --max-instances 10 \
    --set-env-vars "POSTGRES_HOST=127.0.0.1" \
    --set-env-vars "API_EXTERNAL_URL=https://${SERVICE_NAME}-${PROJECT_ID}.${REGION}.run.app"

# Get the service URL
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
    --platform managed \
    --region "${REGION}" \
    --format "value(status.url)")

echo "✅ Deployment completed!"
echo "🌐 Service URL: ${SERVICE_URL}"
echo "📊 Supabase Studio: ${SERVICE_URL}"
echo "🔑 API URL: ${SERVICE_URL}/rest/v1/"

echo ""
echo "📝 Next steps:"
echo "1. Update your .env file with the new API_EXTERNAL_URL"
echo "2. Configure your DNS if using a custom domain"
echo "3. Set up monitoring and logging"