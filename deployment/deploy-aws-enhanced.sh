#!/bin/bash
# AWS ECS Fargate Deployment Script for Supabase
# Enhanced version with robust error handling, monitoring, and production features

set -e

# Configuration with environment variable overrides
AWS_REGION="${AWS_REGION:-ap-south-1}"
CLUSTER_NAME="${CLUSTER_NAME:-supabase-cluster}"
SERVICE_NAME="${SERVICE_NAME:-supabase-service}"
TASK_DEFINITION="${TASK_DEFINITION:-supabase-task}"
ECR_REPOSITORY="${ECR_REPOSITORY:-supabase-selfhosted}"
STACK_NAME="${STACK_NAME:-supabase-infrastructure}"
VPC_CIDR="${VPC_CIDR:-10.0.0.0/16}"
DESIRED_COUNT="${DESIRED_COUNT:-1}"
CPU="${CPU:-2048}"
MEMORY="${MEMORY:-4096}"
ENABLE_LOGGING="${ENABLE_LOGGING:-true}"
ENABLE_MONITORING="${ENABLE_MONITORING:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

log "🚀 Starting Enhanced Supabase AWS ECS Fargate Deployment"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE_NAME="$2"
            shift 2
            ;;
        --cpu)
            CPU="$2"
            shift 2
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --count)
            DESIRED_COUNT="$2"
            shift 2
            ;;
        --no-logging)
            ENABLE_LOGGING="false"
            shift
            ;;
        --no-monitoring)
            ENABLE_MONITORING="false"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -r, --region REGION     AWS Region (default: ap-south-1)"
            echo "  -c, --cluster NAME      ECS Cluster name (default: supabase-cluster)"
            echo "  -s, --service NAME      ECS Service name (default: supabase-service)"
            echo "  --cpu CPU              Task CPU (default: 2048)"
            echo "  --memory MEMORY        Task Memory (default: 4096)"
            echo "  --count COUNT          Desired task count (default: 1)"
            echo "  --no-logging           Disable CloudWatch logging"
            echo "  --no-monitoring        Disable CloudWatch monitoring"
            echo "  -h, --help             Show this help"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Prerequisites check
log "🔍 Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    error "AWS CLI not found. Please install it first: https://aws.amazon.com/cli/"
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    error "Docker not found. Please install Docker first: https://docs.docker.com/get-docker/"
fi

# Check AWS credentials
if ! aws sts get-caller-identity --region "$AWS_REGION" &> /dev/null; then
    error "AWS credentials not configured. Please run 'aws configure' first."
fi

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    error "Dockerfile not found in current directory"
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region "$AWS_REGION")

log "📍 Deployment Configuration:"
info "   Region: ${AWS_REGION}"
info "   Account ID: ${AWS_ACCOUNT_ID}"
info "   Cluster: ${CLUSTER_NAME}"
info "   Service: ${SERVICE_NAME}"
info "   CPU: ${CPU}, Memory: ${MEMORY}"
info "   Desired Count: ${DESIRED_COUNT}"
info "   Logging: ${ENABLE_LOGGING}"
info "   Monitoring: ${ENABLE_MONITORING}"

# Create ECR repository if it doesn't exist
log "🏗️ Setting up ECR repository..."
if ! aws ecr describe-repositories --repository-names "$ECR_REPOSITORY" --region "$AWS_REGION" &> /dev/null; then
    aws ecr create-repository \
        --repository-name "$ECR_REPOSITORY" \
        --region "$AWS_REGION" \
        --image-scanning-configuration scanOnPush=true
    log "✅ ECR repository created: ${ECR_REPOSITORY}"
else
    info "ECR repository already exists: ${ECR_REPOSITORY}"
fi

# Get ECR login token
log "🔐 Authenticating with ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Build and push custom image
log "🔨 Building Supabase Docker image..."
FULL_IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest"

docker build -t "${ECR_REPOSITORY}:latest" .
docker tag "${ECR_REPOSITORY}:latest" "$FULL_IMAGE_URI"

log "📤 Pushing image to ECR..."
docker push "$FULL_IMAGE_URI"

log "✅ Image pushed successfully: ${FULL_IMAGE_URI}"

# Create ECS cluster
log "🏗️ Setting up ECS cluster..."
if ! aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$AWS_REGION" --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
    aws ecs create-cluster \
        --cluster-name "$CLUSTER_NAME" \
        --capacity-providers FARGATE \
        --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
        --region "$AWS_REGION"
    log "✅ ECS cluster created: ${CLUSTER_NAME}"
else
    info "ECS cluster already exists: ${CLUSTER_NAME}"
fi

# Create CloudFormation template for infrastructure
log "☁️ Creating CloudFormation template..."
cat > aws-infrastructure.yml << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Supabase Self-Hosted Infrastructure on AWS ECS Fargate'

Parameters:
  ClusterName:
    Type: String
    Description: ECS Cluster Name
  ServiceName:
    Type: String
    Description: ECS Service Name
  ImageUri:
    Type: String
    Description: Container Image URI
  VpcCidr:
    Type: String
    Default: '10.0.0.0/16'
    Description: VPC CIDR Block
  TaskCpu:
    Type: String
    Default: '2048'
    Description: Task CPU
  TaskMemory:
    Type: String
    Default: '4096'
    Description: Task Memory
  DesiredCount:
    Type: Number
    Default: 1
    Description: Desired number of tasks
  EnableLogging:
    Type: String
    Default: 'true'
    AllowedValues: ['true', 'false']
    Description: Enable CloudWatch logging
  EnableMonitoring:
    Type: String
    Default: 'true'
    AllowedValues: ['true', 'false']
    Description: Enable CloudWatch monitoring

Conditions:
  LoggingEnabled: !Equals [!Ref EnableLogging, 'true']
  MonitoringEnabled: !Equals [!Ref EnableMonitoring, 'true']

Resources:
  # VPC and Networking
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub '${ClusterName}-vpc'

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [0, !Cidr [!Ref VpcCidr, 4, 8]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${ClusterName}-public-subnet-1'

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [1, !Cidr [!Ref VpcCidr, 4, 8]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${ClusterName}-public-subnet-2'

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub '${ClusterName}-igw'

  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref InternetGateway
      VpcId: !Ref VPC

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub '${ClusterName}-public-routes'

  DefaultPublicRoute:
    Type: AWS::EC2::Route
    DependsOn: InternetGatewayAttachment
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet1

  PublicSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet2

  # Security Groups
  LoadBalancerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ALB
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 8000
          ToPort: 8000
          CidrIp: 0.0.0.0/0

  ECSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ECS tasks
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 8000
          ToPort: 8000
          SourceSecurityGroupId: !Ref LoadBalancerSecurityGroup
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref LoadBalancerSecurityGroup

  # Application Load Balancer
  LoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub '${ClusterName}-alb'
      Scheme: internet-facing
      Type: application
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref LoadBalancerSecurityGroup

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Sub '${ServiceName}-tg'
      Port: 8000
      Protocol: HTTP
      VpcId: !Ref VPC
      TargetType: ip
      HealthCheckPath: /
      HealthCheckProtocol: HTTP
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 5

  LoadBalancerListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup
      LoadBalancerArn: !Ref LoadBalancer
      Port: 8000
      Protocol: HTTP

  # CloudWatch Log Group
  LogGroup:
    Type: AWS::Logs::LogGroup
    Condition: LoggingEnabled
    Properties:
      LogGroupName: !Sub '/ecs/${ServiceName}'
      RetentionInDays: 7

  # ECS Task Definition
  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Ref ServiceName
      Cpu: !Ref TaskCpu
      Memory: !Ref TaskMemory
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      ExecutionRoleArn: !Ref TaskExecutionRole
      TaskRoleArn: !Ref TaskRole
      ContainerDefinitions:
        - Name: supabase
          Image: !Ref ImageUri
          PortMappings:
            - ContainerPort: 8000
              Protocol: tcp
            - ContainerPort: 5432
              Protocol: tcp
          LogConfiguration:
            !If
              - LoggingEnabled
              - LogDriver: awslogs
                Options:
                  awslogs-group: !Ref LogGroup
                  awslogs-region: !Ref AWS::Region
                  awslogs-stream-prefix: ecs
              - !Ref AWS::NoValue
          Environment:
            - Name: AWS_REGION
              Value: !Ref AWS::Region
            - Name: API_EXTERNAL_URL
              Value: !Sub 'http://${LoadBalancer.DNSName}:8000'

  # ECS Service
  Service:
    Type: AWS::ECS::Service
    DependsOn: LoadBalancerListener
    Properties:
      ServiceName: !Ref ServiceName
      Cluster: !Ref ClusterName
      LaunchType: FARGATE
      DeploymentConfiguration:
        MaximumPercent: 200
        MinimumHealthyPercent: 100
      DesiredCount: !Ref DesiredCount
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: ENABLED
          SecurityGroups:
            - !Ref ECSSecurityGroup
          Subnets:
            - !Ref PublicSubnet1
            - !Ref PublicSubnet2
      TaskDefinition: !Ref TaskDefinition
      LoadBalancers:
        - ContainerName: supabase
          ContainerPort: 8000
          TargetGroupArn: !Ref TargetGroup

  # IAM Roles
  TaskExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

  TaskRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole

  # CloudWatch Alarms (if monitoring enabled)
  CPUAlarm:
    Type: AWS::CloudWatch::Alarm
    Condition: MonitoringEnabled
    Properties:
      AlarmDescription: High CPU utilization
      MetricName: CPUUtilization
      Namespace: AWS/ECS
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: ServiceName
          Value: !Ref Service
        - Name: ClusterName
          Value: !Ref ClusterName

  MemoryAlarm:
    Type: AWS::CloudWatch::Alarm
    Condition: MonitoringEnabled
    Properties:
      AlarmDescription: High memory utilization
      MetricName: MemoryUtilization
      Namespace: AWS/ECS
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: ServiceName
          Value: !Ref Service
        - Name: ClusterName
          Value: !Ref ClusterName

Outputs:
  LoadBalancerDNS:
    Description: DNS name of the load balancer
    Value: !GetAtt LoadBalancer.DNSName
    Export:
      Name: !Sub '${AWS::StackName}-LoadBalancerDNS'

  SupabaseStudioURL:
    Description: Supabase Studio URL
    Value: !Sub 'http://${LoadBalancer.DNSName}:8000'
    Export:
      Name: !Sub '${AWS::StackName}-SupabaseStudioURL'

  ServiceName:
    Description: ECS Service Name
    Value: !Ref Service
    Export:
      Name: !Sub '${AWS::StackName}-ServiceName'

  ClusterName:
    Description: ECS Cluster Name
    Value: !Ref ClusterName
    Export:
      Name: !Sub '${AWS::StackName}-ClusterName'
EOF

# Deploy CloudFormation stack
log "☁️ Deploying CloudFormation infrastructure stack..."
aws cloudformation deploy \
    --template-file aws-infrastructure.yml \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        ClusterName="$CLUSTER_NAME" \
        ServiceName="$SERVICE_NAME" \
        ImageUri="$FULL_IMAGE_URI" \
        VpcCidr="$VPC_CIDR" \
        TaskCpu="$CPU" \
        TaskMemory="$MEMORY" \
        DesiredCount="$DESIRED_COUNT" \
        EnableLogging="$ENABLE_LOGGING" \
        EnableMonitoring="$ENABLE_MONITORING" \
    --capabilities CAPABILITY_IAM \
    --region "$AWS_REGION"

# Get deployment outputs
log "🌐 Retrieving deployment information..."
LOAD_BALANCER_DNS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text \
    --region "$AWS_REGION")

SUPABASE_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`SupabaseStudioURL`].OutputValue' \
    --output text \
    --region "$AWS_REGION")

# Wait for service to be stable
log "⏳ Waiting for ECS service to stabilize..."
aws ecs wait services-stable \
    --cluster "$CLUSTER_NAME" \
    --services "$SERVICE_NAME" \
    --region "$AWS_REGION"

# Deployment summary
log "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "  🌐 Load Balancer DNS: ${LOAD_BALANCER_DNS}"
echo "  🏠 Supabase Studio: ${SUPABASE_URL}"
echo "  🔑 API Endpoint: http://${LOAD_BALANCER_DNS}:8000/rest/v1/"
echo "  🗄️ Database Host: ${LOAD_BALANCER_DNS}"
echo "  📍 AWS Region: ${AWS_REGION}"
echo "  🎯 ECS Cluster: ${CLUSTER_NAME}"
echo "  🚀 ECS Service: ${SERVICE_NAME}"
echo ""
echo "📋 Next Steps:"
echo "  1. 🔗 Update your client applications to use: ${SUPABASE_URL}"
echo "  2. 🔒 Configure SSL certificate for HTTPS (optional)"
echo "  3. 🏷️ Set up custom domain name (optional)"
echo "  4. 📊 Monitor the service in AWS CloudWatch"
echo "  5. 🔧 Update environment variables as needed"
echo ""
echo "🔧 Management Commands:"
echo "  # Scale service"
echo "  aws ecs update-service --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --desired-count 2"
echo ""
echo "  # View logs"
echo "  aws logs tail /ecs/${SERVICE_NAME} --follow"
echo ""
echo "  # Update service with new image"
echo "  ./deploy-aws.sh"
echo ""
log "🎉 Supabase is now running on AWS ECS Fargate!"