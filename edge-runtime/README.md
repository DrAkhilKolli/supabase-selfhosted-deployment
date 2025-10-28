# Supabase Edge Functions - AWS Deployment

Self-hosted Edge Functions runtime powered by Deno, deployed on AWS ECS Fargate.

## 🚀 Quick Start

```bash
# 1. Configure AWS
aws configure

# 2. Set up parameters
cp parameters.json.example parameters.json
# Edit parameters.json with your actual keys

# 3. Deploy to AWS
./deploy-edge-runtime-aws.sh
```

## 📁 What's Included

- **`Dockerfile`** - Container definition for Edge Runtime
- **`main/index.ts`** - Main service router with JWT auth and CORS
- **`functions/`** - Your Edge Functions (copied from ../volumes/functions)
- **`aws-cloudformation.yaml`** - Complete AWS infrastructure
- **`deploy-edge-runtime-aws.sh`** - Automated deployment script
- **`test-local.sh`** - Local testing with Docker
- **`AWS_EDGE_FUNCTIONS_GUIDE.md`** - Complete documentation

## 🧪 Test Locally First

```bash
./test-local.sh

# Test endpoints
curl http://localhost:9000/health
curl http://localhost:9000/hello-world
```

## 🌐 AWS Deployment

The deployment script creates:
- ✅ VPC with public subnets
- ✅ Application Load Balancer
- ✅ ECS Fargate cluster and service
- ✅ ECR repository for images
- ✅ Auto-scaling (2-10 tasks)
- ✅ CloudWatch logging
- ✅ Health checks

## 📖 Full Documentation

See **[AWS_EDGE_FUNCTIONS_GUIDE.md](./AWS_EDGE_FUNCTIONS_GUIDE.md)** for:
- Architecture overview
- Configuration options
- Security best practices
- Monitoring and troubleshooting
- Cost estimation
- Production checklist

## 🔑 Environment Variables

Configure in `parameters.json`:
- `JWT_SECRET` - From your Supabase .env file
- `ANON_KEY` - From your Supabase .env file
- `SERVICE_ROLE_KEY` - From your Supabase .env file
- `REQUIRE_AUTH` - Set to "true" for production

## 📡 Calling Your Functions

After deployment, access your functions at:

```
https://your-alb-url.amazonaws.com/{function-name}
```

Example:
```bash
curl -X POST https://your-alb-url.amazonaws.com/hello-world \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"message": "Hello!"}'
```

## 💰 Estimated Cost

~$54/month for default configuration (2 tasks, 0.5 vCPU each)

## 🆘 Troubleshooting

```bash
# View logs
LOG_GROUP="/ecs/supabase-edge-runtime-production"
aws logs tail $LOG_GROUP --follow

# Check ECS service status
aws ecs describe-services \
  --cluster supabase-edge-runtime-production-cluster \
  --services supabase-edge-runtime-production-service
```

## 📚 Learn More

- [Supabase Edge Runtime GitHub](https://github.com/supabase/edge-runtime)
- [Deno Runtime](https://deno.land/)
- [AWS ECS Fargate](https://aws.amazon.com/fargate/)

---

**Ready to deploy?** Run `./deploy-edge-runtime-aws.sh` 🚀
