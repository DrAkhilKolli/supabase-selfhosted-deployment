#!/bin/bash

# AWS ECS Fargate Deployment Script for Supabase
# This script deploys Supabase to AWS using ECS Fargate

set -e

echo "🚀 Deploying Supabase to AWS ECS Fargate..."

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-supabase-cluster}
SERVICE_NAME=${SERVICE_NAME:-supabase-service}
ECR_REPOSITORY=${ECR_REPOSITORY:-supabase-self-hosted}

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required"; exit 1; }

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "📋 Configuration:"
echo "  Region: $AWS_REGION"
echo "  Account ID: $AWS_ACCOUNT_ID"
echo "  Cluster: $CLUSTER_NAME"

# Create ECR repository if it doesn't exist
echo "🏗️ Setting up ECR repository..."
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION 2>/dev/null || \
aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION

# Get ECR login token
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push custom image
echo "🔨 Building custom Supabase image..."
docker build -t $ECR_REPOSITORY:latest .
docker tag $ECR_REPOSITORY:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

echo "📤 Pushing image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

# Create ECS cluster
echo "🏗️ Creating ECS cluster..."
aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $AWS_REGION 2>/dev/null || echo "Cluster already exists"

# Deploy CloudFormation stack
echo "☁️ Deploying CloudFormation stack..."
aws cloudformation deploy \
  --template-file aws-ecs-fargate.yml \
  --stack-name supabase-stack \
  --parameter-overrides \
    ClusterName=$CLUSTER_NAME \
    ServiceName=$SERVICE_NAME \
    ImageUri=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest \
  --capabilities CAPABILITY_IAM \
  --region $AWS_REGION

# Get service URL
echo "🌐 Getting service URL..."
LOAD_BALANCER_DNS=$(aws cloudformation describe-stacks \
  --stack-name supabase-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text \
  --region $AWS_REGION)

echo "✅ Deployment complete!"
echo "🌐 Supabase Studio: http://$LOAD_BALANCER_DNS:8000"
echo "🗄️ Database: $LOAD_BALANCER_DNS:5432"

echo "📋 Next steps:"
echo "1. Update your client applications to use: http://$LOAD_BALANCER_DNS:8000"
echo "2. Configure your domain and SSL certificate"
echo "3. Set up monitoring and alerts"