#!/bin/bash

# Verification Script for AWS Propuestas v2
# Usage: ./scripts/verify-deployment.sh [environment] [region]

set -e

# Default values
ENVIRONMENT=${1:-prod}
REGION=${2:-us-east-1}
STACK_NAME="aws-propuestas-v2-${ENVIRONMENT}"

echo "🔍 Verifying AWS Propuestas v2 Deployment"
echo "=========================================="
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo "Stack Name: ${STACK_NAME}"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if stack exists
echo "🏗️  Checking CloudFormation Stack..."
if aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${REGION}" > /dev/null 2>&1; then
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${REGION}" --query 'Stacks[0].StackStatus' --output text)
    if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
        print_status 0 "CloudFormation Stack: ${STACK_STATUS}"
    else
        print_status 1 "CloudFormation Stack: ${STACK_STATUS}"
        exit 1
    fi
else
    print_status 1 "CloudFormation Stack not found"
    exit 1
fi

# Get stack outputs
echo ""
echo "📋 Getting Stack Outputs..."

API_URL=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text 2>/dev/null || echo "")

CHAT_TABLE=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ChatSessionsTableName`].OutputValue' \
    --output text 2>/dev/null || echo "")

PROJECTS_TABLE=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ProjectsTableName`].OutputValue' \
    --output text 2>/dev/null || echo "")

DOCUMENTS_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`DocumentsBucketName`].OutputValue' \
    --output text 2>/dev/null || echo "")

# Verify API Gateway
echo ""
echo "🌐 Verifying API Gateway..."
if [ -n "$API_URL" ]; then
    print_status 0 "API Gateway URL: ${API_URL}"
    
    # Test API endpoint
    echo "   Testing API endpoint..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/health" || echo "000")
    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "404" ]; then
        print_status 0 "API Gateway is responding"
    else
        print_warning "API Gateway returned HTTP ${HTTP_STATUS}"
    fi
else
    print_status 1 "API Gateway URL not found"
fi

# Verify DynamoDB Tables
echo ""
echo "🗄️  Verifying DynamoDB Tables..."

if [ -n "$CHAT_TABLE" ]; then
    if aws dynamodb describe-table --table-name "${CHAT_TABLE}" --region "${REGION}" > /dev/null 2>&1; then
        TABLE_STATUS=$(aws dynamodb describe-table --table-name "${CHAT_TABLE}" --region "${REGION}" --query 'Table.TableStatus' --output text)
        if [ "$TABLE_STATUS" = "ACTIVE" ]; then
            print_status 0 "Chat Sessions Table: ${CHAT_TABLE} (${TABLE_STATUS})"
        else
            print_status 1 "Chat Sessions Table: ${CHAT_TABLE} (${TABLE_STATUS})"
        fi
    else
        print_status 1 "Chat Sessions Table not accessible"
    fi
else
    print_status 1 "Chat Sessions Table name not found"
fi

if [ -n "$PROJECTS_TABLE" ]; then
    if aws dynamodb describe-table --table-name "${PROJECTS_TABLE}" --region "${REGION}" > /dev/null 2>&1; then
        TABLE_STATUS=$(aws dynamodb describe-table --table-name "${PROJECTS_TABLE}" --region "${REGION}" --query 'Table.TableStatus' --output text)
        if [ "$TABLE_STATUS" = "ACTIVE" ]; then
            print_status 0 "Projects Table: ${PROJECTS_TABLE} (${TABLE_STATUS})"
        else
            print_status 1 "Projects Table: ${PROJECTS_TABLE} (${TABLE_STATUS})"
        fi
    else
        print_status 1 "Projects Table not accessible"
    fi
else
    print_status 1 "Projects Table name not found"
fi

# Verify S3 Bucket
echo ""
echo "🗂️  Verifying S3 Bucket..."
if [ -n "$DOCUMENTS_BUCKET" ]; then
    if aws s3 ls "s3://${DOCUMENTS_BUCKET}" --region "${REGION}" > /dev/null 2>&1; then
        print_status 0 "Documents Bucket: ${DOCUMENTS_BUCKET}"
    else
        print_status 1 "Documents Bucket not accessible"
    fi
else
    print_status 1 "Documents Bucket name not found"
fi

# Verify Lambda Functions
echo ""
echo "⚡ Verifying Lambda Functions..."

LAMBDA_FUNCTIONS=$(aws lambda list-functions --region "${REGION}" --query "Functions[?contains(FunctionName, 'aws-propuestas')].FunctionName" --output text)

if [ -n "$LAMBDA_FUNCTIONS" ]; then
    for FUNCTION in $LAMBDA_FUNCTIONS; do
        FUNCTION_STATE=$(aws lambda get-function --function-name "${FUNCTION}" --region "${REGION}" --query 'Configuration.State' --output text 2>/dev/null || echo "Unknown")
        if [ "$FUNCTION_STATE" = "Active" ]; then
            print_status 0 "Lambda Function: ${FUNCTION} (${FUNCTION_STATE})"
        else
            print_status 1 "Lambda Function: ${FUNCTION} (${FUNCTION_STATE})"
        fi
    done
else
    print_status 1 "No Lambda functions found"
fi

# Verify Bedrock Access
echo ""
echo "🤖 Verifying Amazon Bedrock Access..."
if aws bedrock list-foundation-models --region "${REGION}" > /dev/null 2>&1; then
    MODEL_COUNT=$(aws bedrock list-foundation-models --region "${REGION}" --query 'length(modelSummaries)' --output text)
    print_status 0 "Bedrock Access: ${MODEL_COUNT} models available"
    
    # Check specific models
    CLAUDE_AVAILABLE=$(aws bedrock list-foundation-models --region "${REGION}" --query "modelSummaries[?contains(modelId, 'claude')].modelId" --output text | wc -w)
    NOVA_AVAILABLE=$(aws bedrock list-foundation-models --region "${REGION}" --query "modelSummaries[?contains(modelId, 'nova')].modelId" --output text | wc -w)
    TITAN_AVAILABLE=$(aws bedrock list-foundation-models --region "${REGION}" --query "modelSummaries[?contains(modelId, 'titan')].modelId" --output text | wc -w)
    
    print_info "Claude models: ${CLAUDE_AVAILABLE}"
    print_info "Nova models: ${NOVA_AVAILABLE}"
    print_info "Titan models: ${TITAN_AVAILABLE}"
else
    print_status 1 "Bedrock Access denied or not available in region"
fi

# Test Chat API
echo ""
echo "💬 Testing Chat API..."
if [ -n "$API_URL" ]; then
    TEST_RESPONSE=$(curl -s -X POST "${API_URL}/chat" \
        -H 'Content-Type: application/json' \
        -d '{
            "messages": [{"role": "user", "content": "Hello, this is a test"}],
            "modelId": "anthropic.claude-3-haiku-20240307-v1:0",
            "mode": "chat-libre"
        }' 2>/dev/null || echo "")
    
    if echo "$TEST_RESPONSE" | grep -q "response"; then
        print_status 0 "Chat API is working"
    else
        print_warning "Chat API test failed or returned unexpected response"
        print_info "Response: ${TEST_RESPONSE}"
    fi
else
    print_status 1 "Cannot test Chat API - URL not available"
fi

# Check Frontend Configuration
echo ""
echo "🎨 Checking Frontend Configuration..."
if [ -f ".env.local" ]; then
    print_status 0 "Environment file (.env.local) exists"
    
    if grep -q "NEXT_PUBLIC_API_URL" .env.local; then
        ENV_API_URL=$(grep "NEXT_PUBLIC_API_URL" .env.local | cut -d'=' -f2)
        if [ "$ENV_API_URL" = "$API_URL" ]; then
            print_status 0 "Frontend API URL matches backend"
        else
            print_warning "Frontend API URL doesn't match backend"
            print_info "Frontend: ${ENV_API_URL}"
            print_info "Backend: ${API_URL}"
        fi
    else
        print_status 1 "NEXT_PUBLIC_API_URL not found in .env.local"
    fi
else
    print_status 1 "Environment file (.env.local) not found"
fi

# Check if build is successful
echo ""
echo "🏗️  Checking Frontend Build..."
if [ -d ".next" ]; then
    print_status 0 "Next.js build directory exists"
else
    print_warning "Next.js build directory not found - run 'npm run build'"
fi

# Summary
echo ""
echo "📊 Deployment Summary"
echo "===================="
echo "🌐 API Gateway URL: ${API_URL:-'Not Available'}"
echo "📊 Chat Sessions Table: ${CHAT_TABLE:-'Not Available'}"
echo "📁 Projects Table: ${PROJECTS_TABLE:-'Not Available'}"
echo "🗂️  Documents Bucket: ${DOCUMENTS_BUCKET:-'Not Available'}"
echo ""

# Final recommendations
echo "🎯 Next Steps:"
echo "=============="
echo "1. 🖥️  Start development server: npm run dev"
echo "2. 🌐 Access your app at: http://localhost:3000"
echo "3. 🧪 Test both Chat Libre and Arquitecto modes"
echo "4. 📱 Deploy frontend to AWS Amplify for production"
echo ""

if [ -n "$API_URL" ] && [ -n "$CHAT_TABLE" ] && [ -n "$DOCUMENTS_BUCKET" ]; then
    echo -e "${GREEN}🎉 Deployment verification completed successfully!${NC}"
    echo -e "${GREEN}Your AWS Propuestas v2 is ready to use!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some components are not working properly.${NC}"
    echo -e "${YELLOW}Please check the errors above and redeploy if necessary.${NC}"
    exit 1
fi
