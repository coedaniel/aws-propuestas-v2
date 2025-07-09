#!/bin/bash

# Deploy Backend Script for AWS Propuestas v2
# Usage: ./scripts/deploy-backend.sh [environment] [region]

set -e

# Default values
ENVIRONMENT=${1:-prod}
REGION=${2:-us-east-1}
STACK_NAME="aws-propuestas-v2-${ENVIRONMENT}"

echo "🚀 Deploying AWS Propuestas v2 Backend..."
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo "Stack Name: ${STACK_NAME}"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI not found. Please install AWS SAM CLI first."
    echo "Visit: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# Build the SAM application
echo "📦 Building SAM application..."
sam build --template-file infrastructure/template.yaml

# Deploy the SAM application
echo "🚀 Deploying to AWS..."
sam deploy \
    --stack-name "${STACK_NAME}" \
    --capabilities CAPABILITY_IAM \
    --region "${REGION}" \
    --resolve-s3 \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset \
    --parameter-overrides Environment="${ENVIRONMENT}"

# Get the API Gateway URL
API_URL=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

# Get DynamoDB table names
CHAT_TABLE=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ChatSessionsTableName`].OutputValue' \
    --output text)

PROJECTS_TABLE=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ProjectsTableName`].OutputValue' \
    --output text)

# Get S3 bucket name
DOCUMENTS_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`DocumentsBucketName`].OutputValue' \
    --output text)

echo "✅ Backend deployed successfully!"
echo ""
echo "📋 Deployment Information:"
echo "=========================="
echo "🌐 API Gateway URL: ${API_URL}"
echo "📊 Chat Sessions Table: ${CHAT_TABLE}"
echo "📁 Projects Table: ${PROJECTS_TABLE}"
echo "🗂️  Documents Bucket: ${DOCUMENTS_BUCKET}"
echo ""
echo "🔧 Environment Variables for Frontend:"
echo "NEXT_PUBLIC_API_URL=${API_URL}"
echo "NEXT_PUBLIC_REGION=${REGION}"
echo ""
echo "Next steps:"
echo "1. Update your frontend environment variables"
echo "2. Deploy the frontend using: npm run build"
echo "3. Test the API endpoints"
echo ""
echo "🧪 Test API:"
echo "curl -X POST ${API_URL}/chat \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}],\"modelId\":\"anthropic.claude-3-haiku-20240307-v1:0\"}'"
