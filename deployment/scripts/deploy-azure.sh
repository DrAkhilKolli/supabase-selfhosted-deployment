#!/bin/bash
# Deploy Supabase to Azure Container Instances

set -e

RESOURCE_GROUP=""
LOCATION="southeastasia"
CONTAINER_NAME="supabase-selfhosted"
REGISTRY_NAME=""
IMAGE_NAME=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY_NAME="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$RESOURCE_GROUP" ] || [ -z "$REGISTRY_NAME" ]; then
    echo "❌ Resource group and registry name required"
    echo "Usage: ./deploy-azure.sh -g myResourceGroup -r myRegistry"
    exit 1
fi

IMAGE_NAME="${REGISTRY_NAME}.azurecr.io/supabase-selfhosted:latest"

echo "🚀 Deploying Supabase to Azure Container Instances..."
echo "📍 Resource Group: ${RESOURCE_GROUP}"
echo "🌍 Location: ${LOCATION}"
echo "🏷️ Container: ${CONTAINER_NAME}"

# Ensure Azure CLI is authenticated
if ! az account show > /dev/null 2>&1; then
    echo "❌ Please authenticate with Azure CLI first:"
    echo "az login"
    exit 1
fi

# Create resource group if it doesn't exist
echo "🏗️ Creating resource group..."
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"

# Create Azure Container Registry if it doesn't exist
echo "🏗️ Creating Azure Container Registry..."
az acr create --resource-group "${RESOURCE_GROUP}" \
    --name "${REGISTRY_NAME}" \
    --sku Basic \
    --admin-enabled true

# Build and push image to ACR
echo "🏗️ Building and pushing image..."
az acr build --registry "${REGISTRY_NAME}" \
    --image supabase-selfhosted:latest .

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name "${REGISTRY_NAME}" --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name "${REGISTRY_NAME}" --query "passwords[0].value" --output tsv)

# Deploy to Azure Container Instances
echo "🚀 Deploying to Azure Container Instances..."
az container create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CONTAINER_NAME}" \
    --image "${IMAGE_NAME}" \
    --registry-login-server "${REGISTRY_NAME}.azurecr.io" \
    --registry-username "${ACR_USERNAME}" \
    --registry-password "${ACR_PASSWORD}" \
    --dns-name-label "${CONTAINER_NAME}" \
    --ports 8000 5432 \
    --cpu 2 \
    --memory 4 \
    --environment-variables \
        API_EXTERNAL_URL="http://${CONTAINER_NAME}.${LOCATION}.azurecontainer.io:8000"

# Get the container URL
CONTAINER_URL="http://${CONTAINER_NAME}.${LOCATION}.azurecontainer.io:8000"

echo "✅ Deployment completed!"
echo "🌐 Container URL: ${CONTAINER_URL}"
echo "📊 Supabase Studio: ${CONTAINER_URL}"
echo "🔑 API URL: ${CONTAINER_URL}/rest/v1/"

echo ""
echo "📝 Next steps:"
echo "1. Update your .env file with the new API_EXTERNAL_URL"
echo "2. Configure your DNS if using a custom domain"
echo "3. Set up monitoring and logging"