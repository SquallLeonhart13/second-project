#!/bin/bash

# Validate required environment variables

PROJECT_NAME=second-project
ENVIRONMENT=dev

# Load infrastructure details
INFRA_FILE="./aws/${PROJECT_NAME}_${ENVIRONMENT}_infrastructure.txt"
if [ ! -f "$INFRA_FILE" ]; then
    echo "❌ Infrastructure file not found at: $INFRA_FILE"
    exit 1
fi

source "$INFRA_FILE"

# Validate required variables from infrastructure file
REQUIRED_VARS=(
    "AWS_REGION"
    "ECS_CLUSTER_NAME"
    "ECS_SERVICE_NAME"
    "ECS_TASK_FAMILY"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Required variable $var not found in infrastructure file"
        exit 1
    fi
done

# Set ECR repository name
ECR_REPOSITORY_NAME="${PROJECT_NAME}-repo"

# Ensure AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if ECR repository exists, create if it doesn't
echo "Checking ECR repository..."
if ! aws ecr describe-repositories --repository-names $ECR_REPOSITORY_NAME --region $AWS_REGION &> /dev/null; then
    echo "Creating ECR repository $ECR_REPOSITORY_NAME..."
    aws ecr create-repository \
        --repository-name $ECR_REPOSITORY_NAME \
        --region $AWS_REGION
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create ECR repository"
        exit 1
    fi
    echo "✅ ECR repository created successfully"
else
    echo "✅ ECR repository already exists"
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get ECR login token and login to Docker
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker image
echo "Building Docker image..."
docker build -t $ECR_REPOSITORY_NAME .

# Tag the image
ECR_REPO_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME"
docker tag $ECR_REPOSITORY_NAME:latest $ECR_REPO_URI:latest

# Push the image to ECR
echo "Pushing image to ECR..."
docker push $ECR_REPO_URI:latest

# Update ECS service
echo "Updating ECS service..."
aws ecs update-service \
    --cluster $ECS_CLUSTER_NAME \
    --service $ECS_SERVICE_NAME \
    --force-new-deployment \
    --region $AWS_REGION

echo "Deployment completed successfully!"
