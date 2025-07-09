#!/bin/bash

# Complete Setup Script for AWS Propuestas v2
# This script sets up and deploys the entire application

set -e

echo "🚀 AWS Propuestas v2 - Complete Setup"
echo "======================================"

# Default values
ENVIRONMENT=${1:-prod}
REGION=${2:-us-east-1}

echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check AWS CLI
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi
echo "✅ AWS CLI configured"

# Check SAM CLI
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI not found. Please install AWS SAM CLI first."
    exit 1
fi
echo "✅ SAM CLI found"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi
echo "✅ Node.js found ($(node --version))"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install npm first."
    exit 1
fi
echo "✅ npm found ($(npm --version))"

echo ""

# Step 1: Install dependencies
echo "📦 Step 1: Installing dependencies..."
npm install

# Step 2: Deploy Backend
echo "📡 Step 2: Deploying Backend..."
./scripts/deploy-backend.sh "${ENVIRONMENT}" "${REGION}"

# Get the API URL
STACK_NAME="aws-propuestas-v2-${ENVIRONMENT}"
API_URL=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

echo ""

# Step 3: Configure Frontend
echo "🎨 Step 3: Configuring Frontend..."

# Create .env.local file
cat > .env.local << EOF
NEXT_PUBLIC_API_URL=${API_URL}
NEXT_PUBLIC_REGION=${REGION}
NEXT_PUBLIC_ENVIRONMENT=${ENVIRONMENT}
EOF

echo "✅ Environment variables configured in .env.local"

# Step 4: Build Frontend
echo "🔨 Step 4: Building Frontend..."
npm run build

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "🌟 Your AWS Propuestas v2 is ready!"
echo ""
echo "📋 Deployment Information:"
echo "=========================="
echo "🌐 Backend API URL: ${API_URL}"
echo "🖥️  Frontend: Built and ready for deployment"
echo "🌍 Region: ${REGION}"
echo "🏷️  Environment: ${ENVIRONMENT}"
echo ""
echo "🚀 Next Steps:"
echo "=============="
echo "1. 🖥️  Start development server: npm run dev"
echo "2. 🌐 Deploy to Amplify Hosting:"
echo "   - Push code to GitHub"
echo "   - Connect GitHub repo to AWS Amplify"
echo "   - Amplify will auto-deploy on commits"
echo ""
echo "3. 🧪 Test your application:"
echo "   - Chat Libre: Test free conversation with Bedrock models"
echo "   - Arquitecto AWS: Test guided proposal generation"
echo ""
echo "📊 Monitoring:"
echo "=============="
echo "- CloudWatch Logs: /aws/lambda/aws-propuestas-*"
echo "- DynamoDB Tables: aws-propuestas-*-${ENVIRONMENT}"
echo "- S3 Bucket: aws-propuestas-documents-${ENVIRONMENT}-*"
echo ""
echo "🔧 Configuration:"
echo "================="
echo "- Environment file: .env.local"
echo "- Backend stack: ${STACK_NAME}"
echo "- Region: ${REGION}"
echo ""
echo "🎯 Ready to create professional AWS proposals with AI!"
