# Self-Hosted Edge Functions on AWS

Complete guide for deploying Supabase Edge Functions Runtime (Deno-based) to AWS ECS Fargate.

## 🚀 Overview

This setup allows you to:
- **Run Edge Functions**: Deploy JavaScript, TypeScript, and WASM services using Deno runtime
- **Self-Host on AWS**: Complete AWS infrastructure with ECS Fargate, ALB, and CloudWatch
- **JWT Authentication**: Built-in JWT validation and authorization
- **Auto-Scaling**: Automatic scaling based on CPU utilization
- **CORS Support**: Pre-configured CORS for web applications
- **Health Monitoring**: Health checks and CloudWatch logging

## 📋 Prerequisites

### Required Tools
- **AWS CLI**: [Install AWS CLI](https://aws.amazon.com/cli/)
- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
- **AWS Account**: Active AWS account with appropriate permissions

### AWS Permissions Required
- CloudFormation (create/update stacks)
- ECS (create clusters, services, tasks)
- ECR (create repositories, push images)
- EC2 (create VPC, subnets, security groups)
- IAM (create roles and policies)
- ElasticLoadBalancing (create ALB, target groups)
- CloudWatch (create log groups)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Internet                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│           Application Load Balancer (ALB)                    │
│                 Health Check: /health                        │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
┌────────────────────┐  ┌────────────────────┐
│   ECS Fargate      │  │   ECS Fargate      │
│   Edge Runtime     │  │   Edge Runtime     │
│   Container        │  │   Container        │
│   (Deno Runtime)   │  │   (Deno Runtime)   │
└────────────────────┘  └────────────────────┘
         │                       │
         └───────────┬───────────┘
                     ▼
         ┌────────────────────┐
         │  CloudWatch Logs   │
         │   Monitoring       │
         └────────────────────┘
```

## 📁 Project Structure

```
edge-runtime/
├── Dockerfile                      # Container definition
├── main/
│   └── index.ts                   # Main service router (JWT, CORS, routing)
├── functions/                      # Your Edge Functions
│   ├── hello-world/
│   │   └── index.ts
│   ├── ai-assistant/
│   │   └── index.ts
│   └── [your-function]/
│       └── index.ts
├── aws-cloudformation.yaml         # Infrastructure as Code
├── deploy-edge-runtime-aws.sh      # Deployment script
├── test-local.sh                   # Local testing script
└── parameters.json                 # CloudFormation parameters
```

## 🚀 Quick Start

### 1. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and Region
```

### 2. Prepare Your Functions

Copy your Edge Functions to the `functions/` directory:

```bash
cd edge-runtime
mkdir -p functions
cp -r ../volumes/functions/* functions/
```

Each function should have an `index.ts` file with a default export:

```typescript
// functions/my-function/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req: Request) => {
  return new Response(
    JSON.stringify({ message: "Hello from my function!" }),
    { headers: { "Content-Type": "application/json" } }
  );
});
```

### 3. Create Parameters File

Create `parameters.json` with your configuration:

```json
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "supabase-edge-runtime"
  },
  {
    "ParameterKey": "Environment",
    "ParameterValue": "production"
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
    "ParameterValue": "your-jwt-secret-from-env"
  },
  {
    "ParameterKey": "AnonKey",
    "ParameterValue": "your-anon-key-from-env"
  },
  {
    "ParameterKey": "ServiceRoleKey",
    "ParameterValue": "your-service-role-key-from-env"
  },
  {
    "ParameterKey": "RequireAuth",
    "ParameterValue": "true"
  }
]
```

Get your keys from the main `.env` file.

### 4. Deploy to AWS

```bash
cd edge-runtime
./deploy-edge-runtime-aws.sh
```

The script will:
1. ✅ Build Docker image
2. ✅ Push to ECR
3. ✅ Create/update CloudFormation stack
4. ✅ Deploy ECS service
5. ✅ Output your Edge Functions URL

## 🧪 Local Testing

Test your Edge Functions locally before deploying:

```bash
./test-local.sh
```

This will:
- Build the Docker image
- Run Edge Runtime on `http://localhost:9000`
- Test health endpoint

### Test Your Functions Locally

```bash
# Health check
curl http://localhost:9000/health

# Test hello-world function
curl http://localhost:9000/hello-world

# Test with authentication
curl -H "Authorization: Bearer YOUR_ANON_KEY" \
     http://localhost:9000/your-function
```

## 📡 Calling Edge Functions

### From JavaScript/TypeScript

```typescript
const EDGE_RUNTIME_URL = "https://your-alb-url.amazonaws.com";
const ANON_KEY = "your-anon-key";

async function callEdgeFunction(functionName: string, data: any) {
  const response = await fetch(`${EDGE_RUNTIME_URL}/${functionName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${ANON_KEY}`,
      'apikey': ANON_KEY
    },
    body: JSON.stringify(data)
  });
  
  return response.json();
}

// Usage
const result = await callEdgeFunction('hello-world', { name: 'World' });
console.log(result);
```

### Using Supabase Client

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://your-alb-url.amazonaws.com',
  'your-anon-key'
)

const { data, error } = await supabase.functions.invoke('hello-world', {
  body: { name: 'World' }
})
```

### From curl

```bash
# Without authentication (if REQUIRE_AUTH=false)
curl -X POST https://your-alb-url.amazonaws.com/hello-world \
  -H "Content-Type: application/json" \
  -d '{"name": "World"}'

# With authentication
curl -X POST https://your-alb-url.amazonaws.com/hello-world \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{"name": "World"}'
```

## 🔧 Configuration

### Environment Variables

The following environment variables are configured in CloudFormation:

| Variable | Description | Required |
|----------|-------------|----------|
| `JWT_SECRET` | Secret for JWT validation | Yes |
| `ANON_KEY` | Supabase anonymous key | Yes |
| `SERVICE_ROLE_KEY` | Supabase service role key | Yes |
| `REQUIRE_AUTH` | Require authentication (true/false) | No (default: true) |
| `ENVIRONMENT` | Environment name | No |

### CloudFormation Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ProjectName` | Project name for resources | supabase-edge-runtime |
| `Environment` | Environment (dev/staging/prod) | production |
| `DesiredCount` | Number of tasks to run | 2 |
| `CPU` | Task CPU units (256-4096) | 512 |
| `Memory` | Task memory in MB | 1024 |

### Scaling Configuration

- **Min Capacity**: Value of `DesiredCount` parameter
- **Max Capacity**: 10 tasks
- **Target CPU**: 70%
- **Scale Out**: 60 seconds cooldown
- **Scale In**: 300 seconds cooldown

## 📊 Monitoring

### CloudWatch Logs

View logs in real-time:

```bash
# Get log group name from CloudFormation outputs
LOG_GROUP=$(aws cloudformation describe-stacks \
  --stack-name supabase-edge-runtime-production \
  --query "Stacks[0].Outputs[?OutputKey=='LogGroupName'].OutputValue" \
  --output text)

# Tail logs
aws logs tail $LOG_GROUP --follow
```

### CloudWatch Metrics

Monitor these metrics in CloudWatch:
- **CPUUtilization**: Track CPU usage
- **MemoryUtilization**: Track memory usage
- **RequestCount**: Number of requests to ALB
- **TargetResponseTime**: Response time from Edge Functions
- **HealthyHostCount**: Number of healthy tasks

### Health Checks

The ALB performs health checks every 30 seconds:
- **Endpoint**: `/health`
- **Timeout**: 10 seconds
- **Healthy Threshold**: 2 consecutive successes
- **Unhealthy Threshold**: 3 consecutive failures

## 🔄 Updating Edge Functions

### Update Existing Functions

1. Modify your function code in `functions/`
2. Run the deployment script:

```bash
./deploy-edge-runtime-aws.sh
```

The script will:
- Build new Docker image
- Push to ECR with new timestamp tag
- Force new ECS deployment
- Perform rolling update (zero downtime)

### Add New Functions

1. Create new function directory:

```bash
mkdir -p functions/my-new-function
```

2. Create `index.ts`:

```typescript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req: Request) => {
  // Your function code
  return new Response(JSON.stringify({ message: "New function!" }), {
    headers: { "Content-Type": "application/json" }
  });
});
```

3. Deploy:

```bash
./deploy-edge-runtime-aws.sh
```

4. Access your new function:

```bash
curl https://your-alb-url.amazonaws.com/my-new-function
```

## 🛡️ Security Best Practices

### 1. JWT Authentication

Always enable JWT authentication in production:

```json
{
  "ParameterKey": "RequireAuth",
  "ParameterValue": "true"
}
```

### 2. Use Secrets Manager

Instead of plain text parameters, use AWS Secrets Manager:

```bash
# Store secrets
aws secretsmanager create-secret \
  --name supabase-jwt-secret \
  --secret-string "your-jwt-secret"

# Update CloudFormation to reference secrets
```

### 3. Enable HTTPS

Add an ACM certificate to the ALB:

```yaml
Listeners:
  - Protocol: HTTPS
    Port: 443
    Certificates:
      - CertificateArn: arn:aws:acm:region:account:certificate/xxx
```

### 4. Restrict Access

Update security groups to limit access:

```yaml
SecurityGroupIngress:
  - IpProtocol: tcp
    FromPort: 443
    ToPort: 443
    CidrIp: YOUR_IP_RANGE/32  # Restrict to your IP
```

### 5. Enable WAF

Add AWS WAF for additional protection against common attacks.

## 🚨 Troubleshooting

### Container Won't Start

Check ECS logs:

```bash
aws logs tail /ecs/supabase-edge-runtime-production --follow
```

Common issues:
- Missing environment variables
- Invalid JWT secret
- Function syntax errors

### Health Check Failing

1. Test health endpoint directly:

```bash
# Get task IP
TASK_IP=$(aws ecs describe-tasks ... --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address')

# Test health
curl http://$TASK_IP:9000/health
```

2. Check container logs for errors

### Function Not Found

Ensure function directory structure is correct:

```
functions/
└── your-function/
    └── index.ts  # Must be named index.ts
```

### Authentication Errors

1. Verify JWT_SECRET matches your Supabase instance
2. Check that ANON_KEY is correct
3. Ensure Authorization header is properly formatted:

```
Authorization: Bearer YOUR_KEY
```

## 💰 Cost Estimation

Approximate monthly AWS costs:

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| ECS Fargate | 2 tasks (0.5 vCPU, 1GB RAM) | ~$30 |
| ALB | Standard load balancer | ~$20 |
| ECR | Image storage (<1GB) | ~$1 |
| CloudWatch Logs | 5GB/month | ~$3 |
| **Total** | | **~$54/month** |

*Costs vary by region and actual usage. Add data transfer costs if applicable.*

## 🎯 Production Checklist

- [ ] Enable HTTPS with ACM certificate
- [ ] Set up custom domain with Route 53
- [ ] Configure AWS WAF
- [ ] Enable CloudWatch alarms
- [ ] Set up AWS Secrets Manager for sensitive values
- [ ] Configure backup and disaster recovery
- [ ] Enable AWS Config for compliance
- [ ] Set up CI/CD pipeline
- [ ] Configure log retention policies
- [ ] Enable AWS X-Ray for tracing
- [ ] Set up CloudWatch dashboards
- [ ] Configure budget alerts

## 📚 Additional Resources

- [Supabase Edge Runtime](https://github.com/supabase/edge-runtime)
- [Deno Documentation](https://deno.land/manual)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)

## 🤝 Support

For issues:
1. Check CloudWatch logs
2. Review ECS service events
3. Verify CloudFormation stack status
4. Test functions locally first

---

**Next Steps**: Deploy your Edge Functions to AWS and start building serverless applications! 🚀