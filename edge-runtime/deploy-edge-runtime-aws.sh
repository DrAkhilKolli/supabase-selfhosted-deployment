#!/bin/bash
set -e

# Self-Hosted Edge Functions AWS Deployment Script
# This script builds, pushes, and deploys the Edge Runtime to AWS ECS

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="supabase-edge-runtime"
ENVIRONMENT="${ENVIRONMENT:-production}"
AWS_REGION="${AWS_REGION:-us-east-1}"
STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker not found. Please install it first."
    exit 1
fi

print_info "==================================================="
print_info "Self-Hosted Edge Functions AWS Deployment"
print_info "==================================================="
print_info "Project: $PROJECT_NAME"
print_info "Environment: $ENVIRONMENT"
print_info "AWS Region: $AWS_REGION"
print_info "Stack Name: $STACK_NAME"
print_info "==================================================="

# Step 1: Check if CloudFormation stack exists
print_info "Step 1: Checking CloudFormation stack status..."
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" &> /dev/null; then
    print_info "Stack exists. Will update existing stack."
    STACK_EXISTS=true
else
    print_info "Stack does not exist. Will create new stack."
    STACK_EXISTS=false
fi

# Step 2: Get or create ECR repository
print_info "Step 2: Setting up ECR repository..."

if [ "$STACK_EXISTS" = true ]; then
    # Get ECR repository URI from stack outputs
    ECR_URI=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='ECRRepositoryURI'].OutputValue" \
        --output text)
    print_info "ECR Repository: $ECR_URI"
else
    # ECR will be created by CloudFormation
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-${ENVIRONMENT}"
    print_info "ECR Repository will be created: $ECR_URI"
fi

# Step 3: Build Docker image
print_info "Step 3: Building Docker image..."
cd "$(dirname "$0")"

# Copy functions directory if it doesn't exist
if [ ! -d "functions" ]; then
    print_warn "Functions directory not found. Creating with sample functions..."
    mkdir -p functions
    cp -r ../volumes/functions/* functions/ 2>/dev/null || true
fi

docker build -t "${PROJECT_NAME}:latest" -f Dockerfile ..
print_info "Docker image built successfully"

# Step 4: Authenticate Docker to ECR
print_info "Step 4: Authenticating Docker to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "${ECR_URI%/*}"
print_info "Docker authenticated to ECR"

# Step 5: Tag and push image
print_info "Step 5: Pushing image to ECR..."
docker tag "${PROJECT_NAME}:latest" "${ECR_URI}:latest"
docker tag "${PROJECT_NAME}:latest" "${ECR_URI}:$(date +%Y%m%d-%H%M%S)"

# Create ECR repository if it doesn't exist (for new stacks)
if [ "$STACK_EXISTS" = false ]; then
    aws ecr create-repository \
        --repository-name "${PROJECT_NAME}-${ENVIRONMENT}" \
        --region "$AWS_REGION" \
        --image-scanning-configuration scanOnPush=true \
        2>/dev/null || print_warn "ECR repository may already exist"
fi

docker push "${ECR_URI}:latest"
docker push "${ECR_URI}:$(date +%Y%m%d-%H%M%S)"
print_info "Image pushed to ECR successfully"

# Step 6: Deploy or update CloudFormation stack
print_info "Step 6: Deploying CloudFormation stack..."

# Check if parameters file exists
if [ ! -f "parameters.json" ]; then
    print_warn "parameters.json not found. Creating template..."
    cat > parameters.json << EOF
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "${PROJECT_NAME}"
  },
  {
    "ParameterKey": "Environment",
    "ParameterValue": "${ENVIRONMENT}"
  },
  {
    "ParameterKey": "DesiredCount",
    "ParameterValue": "2"
  },
  {
    "ParameterKey": "CPU",
    "ParameterValue": "512"
  },
  {
    "ParameterKey": "Memory",
    "ParameterValue": "1024"
  },
  {
    "ParameterKey": "JWTSecret",
    "ParameterValue": "$(openssl rand -base64 32)"
  },
  {
    "ParameterKey": "AnonKey",
    "ParameterValue": "your-anon-key-here"
  },
  {
    "ParameterKey": "ServiceRoleKey",
    "ParameterValue": "your-service-role-key-here"
  },
  {
    "ParameterKey": "RequireAuth",
    "ParameterValue": "true"
  }
]
EOF
    print_warn "Created parameters.json template. Please update with your actual keys!"
    print_error "Stopping deployment. Update parameters.json and run again."
    exit 1
fi

if [ "$STACK_EXISTS" = true ]; then
    print_info "Updating existing stack..."
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://aws-cloudformation.yaml \
        --parameters file://parameters.json \
        --capabilities CAPABILITY_IAM \
        --region "$AWS_REGION" || {
            if [ $? -eq 254 ]; then
                print_warn "No updates to be performed."
            else
                print_error "Stack update failed"
                exit 1
            fi
        }
    
    print_info "Waiting for stack update to complete..."
    aws cloudformation wait stack-update-complete \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" || {
            print_error "Stack update failed or timed out"
            exit 1
        }
else
    print_info "Creating new stack..."
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://aws-cloudformation.yaml \
        --parameters file://parameters.json \
        --capabilities CAPABILITY_IAM \
        --region "$AWS_REGION"
    
    print_info "Waiting for stack creation to complete (this may take 5-10 minutes)..."
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" || {
            print_error "Stack creation failed or timed out"
            exit 1
        }
fi

# Step 7: Force new ECS deployment
print_info "Step 7: Forcing new ECS deployment..."
CLUSTER_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='ECSClusterName'].OutputValue" \
    --output text)

SERVICE_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='ECSServiceName'].OutputValue" \
    --output text)

aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --force-new-deployment \
    --region "$AWS_REGION" > /dev/null

print_info "New deployment initiated"

# Step 8: Get outputs
print_info "Step 8: Retrieving deployment information..."
ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" \
    --output text)

LOG_GROUP=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='LogGroupName'].OutputValue" \
    --output text)

print_info "==================================================="
print_info "Deployment completed successfully!"
print_info "==================================================="
print_info "Load Balancer URL: $ALB_URL"
print_info "Health Check: $ALB_URL/health"
print_info "CloudWatch Logs: $LOG_GROUP"
print_info "==================================================="
print_info "Test your Edge Functions:"
print_info "  curl $ALB_URL/hello-world"
print_info "  curl $ALB_URL/ai-assistant"
print_info "==================================================="
print_info ""
print_info "To view logs:"
print_info "  aws logs tail $LOG_GROUP --follow --region $AWS_REGION"
print_info ""
print_info "To update Edge Functions:"
print_info "  1. Update functions in ./functions/"
print_info "  2. Run this script again: ./deploy-edge-runtime-aws.sh"
print_info ""
print_info "==================================================="
