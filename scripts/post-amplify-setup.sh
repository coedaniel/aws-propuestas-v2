#!/bin/bash

# Post-Amplify Setup Script
# Run this after Amplify deployment is complete

set -e

echo "🚀 AWS Propuestas v2 - Post-Amplify Setup"
echo "========================================"

# Get Amplify app details
echo "📱 Getting Amplify app information..."

# You'll need to replace APP_ID with your actual Amplify App ID
APP_ID=${1:-""}

if [ -z "$APP_ID" ]; then
    echo "❌ Please provide Amplify App ID as first argument"
    echo "Usage: ./scripts/post-amplify-setup.sh <APP_ID>"
    echo ""
    echo "You can find your App ID in the Amplify Console URL:"
    echo "https://console.aws.amazon.com/amplify/home?region=us-east-1#/[APP_ID]"
    exit 1
fi

# Get app details
echo "🔍 Fetching app details..."
APP_DETAILS=$(aws amplify get-app --app-id "$APP_ID" --region us-east-1)
APP_URL=$(echo "$APP_DETAILS" | jq -r '.app.defaultDomain')

echo "✅ App URL: https://$APP_URL"

# Test the deployment
echo ""
echo "🧪 Testing deployment..."

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s "https://v13oiy941a.execute-api.us-east-1.amazonaws.com/prod/health" || echo "failed")

if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✅ Backend API is healthy"
else
    echo "❌ Backend API health check failed"
fi

# Test frontend
echo "Testing frontend..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$APP_URL" || echo "000")

if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend is accessible"
else
    echo "❌ Frontend returned HTTP $FRONTEND_RESPONSE"
fi

echo ""
echo "🎉 Deployment Summary"
echo "===================="
echo "🌐 Frontend URL: https://$APP_URL"
echo "📡 Backend API: https://v13oiy941a.execute-api.us-east-1.amazonaws.com/prod"
echo "📊 GitHub Repo: https://github.com/coedaniel/aws-propuestas-v2"
echo ""
echo "🎯 Next Steps:"
echo "=============="
echo "1. 🧪 Test Chat Libre mode"
echo "2. 🏗️  Test Arquitecto AWS mode"
echo "3. 🔧 Customize prompts and flows"
echo "4. 📱 Configure custom domain (optional)"
echo "5. 🔍 Monitor usage and costs"
echo ""
echo "🚀 Your AWS Propuestas v2 is live in production!"
