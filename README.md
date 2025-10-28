# Supabase Self-Hosted Cloud Deployment

🚀 **Production-ready Supabase self-hosted setup with secure configuration, S3 storage, BigQuery analytics, and multi-cloud deployment scripts for AWS, GCP, and Azure**

## ✨ Features

- 🔒 **Security-first**: All secrets generated with cryptographic security
- 🌍 **Multi-cloud ready**: AWS, GCP, Azure deployment configurations
- 📊 **Analytics configured**: Postgres + BigQuery backend options
- 🤖 **AI Assistant**: OpenAI integration for SQL Editor
- 💾 **S3 Storage**: AWS S3 backend configuration
- 🐳 **Containerized**: Docker images for easy deployment

## 🏗️ Architecture

```
├── docker-compose.yml          # Main service orchestration
├── docker-compose.s3.yml       # S3 storage variant
├── docker-compose-multi.yml    # Multi-project setup
├── .env                        # Environment configuration
├── gcloud.json                 # BigQuery service account
├── volumes/                    # Persistent data
├── deployment/                 # Cloud deployment configs
└── docs/                      # Documentation
```

## 🚀 Quick Start

### Local Development
```bash
# Clone repository
git clone https://github.com/DrAkhilKolli/supabase-selfhosted-deployment.git
cd supabase-selfhosted-deployment

# Start services
docker compose up -d

# Access Supabase Studio
open http://localhost:8000
```

### Cloud Deployment
```bash
# AWS ECS Fargate
./deployment/deploy-aws.sh

# Google Cloud Run
./deployment/scripts/deploy-gcp.sh -p your-project-id

# Azure Container Instances
./deployment/scripts/deploy-azure.sh -g myResourceGroup -r myRegistry
```

## 🔐 Security Configuration

All secrets are cryptographically generated:
- JWT Secret (32 chars)
- Database passwords
- API keys (ANON/SERVICE_ROLE)
- Encryption keys

**⚠️ Important**: Update `.env` for production deployment.

## 📊 Analytics Options

### Postgres Backend (Default)
- Good for development and light usage
- Uses existing database
- Immediate setup

### BigQuery Backend (Production)
- Scalable and production-ready
- Advanced querying features
- Requires Google Cloud setup

Switch backends by updating `.env` configuration.

## 🌐 Access Points

- **Supabase Studio**: `http://localhost:8000`
- **Database**: `localhost:5432`
- **API Gateway**: `localhost:8000`
- **Analytics Dashboard**: `http://localhost:4000/dashboard`

## 🔧 Configuration

### Environment Variables
Key variables in `.env`:
- `POSTGRES_PASSWORD`: Database password
- `JWT_SECRET`: JWT signing key
- `ANON_KEY`: Public API key
- `SERVICE_ROLE_KEY`: Service API key
- `OPENAI_API_KEY`: AI assistant

### Storage Configuration
- **Backend**: S3
- **Bucket**: `storage4supabase`
- **Region**: `ap-south-2` (Asia Pacific - Hyderabad)

## 📚 Documentation

- [Analytics Configuration](ANALYTICS_CONFIG.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Security Best Practices](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🚀 Deployment Status

- ✅ Core services configured
- ✅ Security hardened
- ✅ S3 storage ready
- ✅ AI assistant enabled
- ✅ Analytics configured
- ✅ Docker containerized

## 🏷️ Version

**Current Version**: 1.0.0
**Supabase Version**: Latest stable
**Last Updated**: October 28, 2025

---

Built with ❤️ for production-scale Supabase deployments
