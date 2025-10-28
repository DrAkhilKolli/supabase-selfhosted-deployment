# Cloud Deployment Configurations

This directory contains deployment scripts and configurations for various cloud platforms.

## Available Deployments

### AWS (Amazon Web Services)
- **ECS Fargate**: Serverless container deployment
- **EC2**: Virtual machine deployment
- **EKS**: Kubernetes deployment

### Google Cloud Platform
- **Cloud Run**: Serverless containers
- **Compute Engine**: Virtual machines
- **GKE**: Kubernetes clusters

### Microsoft Azure
- **Container Instances**: Serverless containers
- **Virtual Machines**: Traditional VMs
- **AKS**: Azure Kubernetes Service

## Quick Deploy Commands

```bash
# AWS ECS Fargate
./deploy-aws.sh

# Google Cloud Run
./deploy-gcp.sh

# Azure Container Instances
./deploy-azure.sh

# Kubernetes (any provider)
./deploy-k8s.sh
```

## Prerequisites

1. **Cloud CLI tools installed**:
   - AWS CLI
   - Google Cloud SDK
   - Azure CLI

2. **Docker installed and configured**

3. **Environment variables configured**

## Security Notes

- All deployment scripts use secure environment variable injection
- Secrets are never hardcoded in deployment files
- Use cloud-native secret management services