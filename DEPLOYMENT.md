# 🚀 Supabase Self-Hosted Deployment Guide

This repository contains a production-ready Supabase self-hosted setup with secure configuration and multi-cloud deployment options.

## 🏗️ Project Structure

```
supabase-project/
├── docker-compose.yml              # Main Docker Compose configuration
├── docker-compose.s3.yml          # S3 storage configuration
├── docker-compose-multi.yml       # Multi-platform deployment
├── Dockerfile                     # Custom Supabase image
├── .env.template                  # Environment template
├── entrypoint.sh                  # Container startup script
├── healthcheck.sh                 # Health monitoring script
├── volumes/                       # Data persistence
├── deployment/
│   ├── deploy-aws.sh             # AWS ECS Fargate deployment
│   └── scripts/
│       ├── build-image.sh        # Build Docker image
│       ├── push-image.sh         # Push to registries
│       ├── deploy-gcp.sh         # Google Cloud Run deployment
│       └── deploy-azure.sh       # Azure Container Instances
├── gcloud.json                   # BigQuery service account
└── ANALYTICS_CONFIG.md           # Analytics configuration guide
```

## 🔐 Security Features

- **Secure Secrets**: All JWT tokens and passwords generated with OpenSSL
- **Database Encryption**: Encrypted PostgreSQL connection
- **Environment Isolation**: Template-based configuration
- **S3 Backend**: Secure object storage with AWS S3
- **Analytics Privacy**: BigQuery integration with service account

## 🚀 Quick Start

### Local Development

1. **Clone and setup:**
   ```bash
   git clone <your-repo-url>
   cd supabase-project
   cp .env.template .env
   # Edit .env with your values
   ```

2. **Start services:**
   ```bash
   docker-compose up -d
   ```

3. **Access Supabase Studio:**
   ```
   http://localhost:8000
   ```

### Docker Image Deployment

1. **Build the image:**
   ```bash
   ./deployment/scripts/build-image.sh
   ```

2. **Test locally:**
   ```bash
   docker run -d -p 8000:8000 -p 5432:5432 supabase-selfhosted:latest
   ```

## ☁️ Cloud Deployment Options

### AWS ECS Fargate

```bash
./deployment/deploy-aws.sh
```

Features:
- Auto-scaling ECS service
- Application Load Balancer
- CloudWatch logging
- ECR container registry

### Google Cloud Run

```bash
./deployment/scripts/deploy-gcp.sh -p your-project-id
```

Features:
- Serverless container deployment
- Automatic scaling
- Cloud Build integration
- Regional deployment

### Azure Container Instances

```bash
./deployment/scripts/deploy-azure.sh -g myResourceGroup -r myRegistry
```

Features:
- Simple container hosting
- Azure Container Registry
- Public IP assignment
- Resource group management

## 🔧 Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | `secure_password_123` |
| `JWT_SECRET` | JWT signing secret | `your-jwt-secret` |
| `ANON_KEY` | Anonymous access key | `generated-anon-key` |
| `SERVICE_ROLE_KEY` | Service role key | `generated-service-key` |
| `AWS_ACCESS_KEY_ID` | S3 access key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key | `...` |
| `OPENAI_API_KEY` | AI assistant key | `sk-...` |

### S3 Storage Setup

1. Create an S3 bucket in `ap-south-2` region
2. Configure IAM user with S3 permissions
3. Update `.env` with credentials:
   ```env
   GLOBAL_S3_BUCKET=your-bucket-name
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   ```

### Analytics Configuration

Choose between Postgres (default) or BigQuery:

**Postgres Analytics:**
```env
ANALYTICS_ENABLED=true
```

**BigQuery Analytics:**
```env
BIGQUERY_PROJECT_ID=your-project-id
BIGQUERY_DATASET_ID=supabase_analytics
GOOGLE_APPLICATION_CREDENTIALS=/app/gcloud.json
```

See [ANALYTICS_CONFIG.md](ANALYTICS_CONFIG.md) for detailed setup.

## 📊 Monitoring & Health Checks

### Built-in Health Checks

The container includes automatic health monitoring:
- Supabase Studio (port 8000)
- PostgreSQL (port 5432)
- Auth Service (port 9999)

### Manual Health Check

```bash
docker exec <container-id> /healthcheck.sh
```

### Logs

```bash
# View all services
docker-compose logs -f

# Specific service
docker-compose logs -f studio
```

## 🔄 Backup & Recovery

### Database Backup

```bash
# Create backup
docker exec supabase-db pg_dump -U postgres postgres > backup.sql

# Restore backup
docker exec -i supabase-db psql -U postgres postgres < backup.sql
```

### Volume Backup

```bash
# Backup volumes
tar -czf volumes-backup.tar.gz volumes/

# Restore volumes
tar -xzf volumes-backup.tar.gz
```

## 🚢 Container Registry Options

### Docker Hub

```bash
./deployment/scripts/push-image.sh -r yourusername
```

### AWS ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
./deployment/scripts/push-image.sh -r 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Google Container Registry

```bash
gcloud auth configure-docker
./deployment/scripts/push-image.sh -r gcr.io/project-id
```

## 🔧 Troubleshooting

### Common Issues

1. **Port conflicts:**
   ```bash
   # Change ports in docker-compose.yml
   ports:
     - "8001:8000"  # Studio
     - "5433:5432"  # PostgreSQL
   ```

2. **Database connection issues:**
   ```bash
   # Reset database volumes
   docker-compose down -v
   docker-compose up -d
   ```

3. **Analytics service failing:**
   ```bash
   # Disable analytics temporarily
   docker-compose up -d --scale analytics=0
   ```

### Logs and Debugging

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Access container shell
docker exec -it supabase-studio /bin/bash
```

## 🔒 Security Best Practices

1. **Change default passwords** in `.env`
2. **Use HTTPS** in production (configure reverse proxy)
3. **Restrict database access** to application only
4. **Regular backups** and security updates
5. **Monitor access logs** and set up alerts
6. **Use secrets management** for sensitive data

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Azure Container Instances Documentation](https://docs.microsoft.com/en-us/azure/container-instances/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**🎉 Happy deploying!** For issues or questions, please open a GitHub issue.