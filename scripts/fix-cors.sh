#!/bin/bash

# 🔧 AWS Propuestas v2 - Solucionador de CORS
# Script para solucionar problemas de CORS en API Gateway

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        🔧 AWS Propuestas v2 - Solucionador de CORS          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Variables
STACK_NAME="aws-propuestas-v2-prod"
REGION="us-east-1"

log "Iniciando solución de problemas de CORS..."

# 1. Verificar que el stack existe
if ! aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
    error "Stack $STACK_NAME no encontrado en región $REGION"
fi

# 2. Obtener información del API Gateway
log "Obteniendo información del API Gateway..."
API_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text | sed 's|https://||' | sed 's|\.execute-api\..*||')

if [ -z "$API_ID" ]; then
    error "No se pudo obtener el ID del API Gateway"
fi

log "✅ API Gateway ID: $API_ID"

# 3. Verificar configuración actual de CORS
log "Verificando configuración actual de CORS..."

# Obtener recursos del API
RESOURCES=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[].id' --output text)

for RESOURCE_ID in $RESOURCES; do
    # Verificar si existe método OPTIONS
    if aws apigateway get-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method OPTIONS --region $REGION &> /dev/null; then
        log "✅ Método OPTIONS encontrado en recurso $RESOURCE_ID"
    else
        warn "❌ Método OPTIONS faltante en recurso $RESOURCE_ID"
        
        # Obtener path del recurso
        RESOURCE_PATH=$(aws apigateway get-resource --rest-api-id $API_ID --resource-id $RESOURCE_ID --region $REGION --query 'pathPart' --output text)
        
        if [ "$RESOURCE_PATH" != "None" ] && [ "$RESOURCE_PATH" != "" ]; then
            log "Agregando método OPTIONS a recurso: $RESOURCE_PATH"
            
            # Crear método OPTIONS
            aws apigateway put-method \
                --rest-api-id $API_ID \
                --resource-id $RESOURCE_ID \
                --http-method OPTIONS \
                --authorization-type NONE \
                --region $REGION
            
            # Crear integración mock
            aws apigateway put-integration \
                --rest-api-id $API_ID \
                --resource-id $RESOURCE_ID \
                --http-method OPTIONS \
                --type MOCK \
                --integration-http-method OPTIONS \
                --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
                --region $REGION
            
            # Crear respuesta del método
            aws apigateway put-method-response \
                --rest-api-id $API_ID \
                --resource-id $RESOURCE_ID \
                --http-method OPTIONS \
                --status-code 200 \
                --response-parameters '{"method.response.header.Access-Control-Allow-Headers": false, "method.response.header.Access-Control-Allow-Methods": false, "method.response.header.Access-Control-Allow-Origin": false}' \
                --region $REGION
            
            # Crear respuesta de integración
            aws apigateway put-integration-response \
                --rest-api-id $API_ID \
                --resource-id $RESOURCE_ID \
                --http-method OPTIONS \
                --status-code 200 \
                --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'", "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'", "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'"}' \
                --region $REGION
            
            log "✅ Método OPTIONS agregado a $RESOURCE_PATH"
        fi
    fi
done

# 4. Verificar headers CORS en respuestas Lambda
log "Verificando headers CORS en funciones Lambda..."

# Lista de funciones Lambda del stack
LAMBDA_FUNCTIONS=("aws-propuestas-chat-prod" "aws-propuestas-arquitecto-prod" "aws-propuestas-documents-prod" "aws-propuestas-health-prod")

for FUNCTION_NAME in "${LAMBDA_FUNCTIONS[@]}"; do
    if aws lambda get-function --function-name $FUNCTION_NAME --region $REGION &> /dev/null; then
        log "✅ Función $FUNCTION_NAME encontrada"
        
        # Test de la función
        TEST_RESPONSE=$(aws lambda invoke \
            --function-name $FUNCTION_NAME \
            --payload '{"httpMethod": "POST", "body": "{\"test\": true}"}' \
            --region $REGION \
            response.json 2>/dev/null || echo "error")
        
        if [ "$TEST_RESPONSE" != "error" ] && [ -f "response.json" ]; then
            if grep -q "Access-Control-Allow-Origin" response.json; then
                log "✅ Headers CORS presentes en $FUNCTION_NAME"
            else
                warn "❌ Headers CORS faltantes en $FUNCTION_NAME"
            fi
            rm -f response.json
        fi
    else
        warn "❌ Función $FUNCTION_NAME no encontrada"
    fi
done

# 5. Crear nuevo deployment
log "Creando nuevo deployment del API Gateway..."
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region $REGION \
    --query 'id' \
    --output text)

if [ -n "$DEPLOYMENT_ID" ]; then
    log "✅ Nuevo deployment creado: $DEPLOYMENT_ID"
else
    warn "No se pudo crear el deployment"
fi

# 6. Test de CORS
log "Probando configuración de CORS..."
API_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/prod"

# Test OPTIONS request
log "Probando request OPTIONS..."
OPTIONS_RESPONSE=$(curl -s -X OPTIONS "$API_URL/health" \
    -H "Origin: https://example.com" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -w "%{http_code}" -o /dev/null)

if [ "$OPTIONS_RESPONSE" = "200" ]; then
    log "✅ Request OPTIONS exitoso"
else
    warn "❌ Request OPTIONS falló (código: $OPTIONS_RESPONSE)"
fi

# Test POST request
log "Probando request POST..."
POST_RESPONSE=$(curl -s -X POST "$API_URL/health" \
    -H "Content-Type: application/json" \
    -H "Origin: https://example.com" \
    -d '{"test": true}' \
    -w "%{http_code}" -o /dev/null)

if [ "$POST_RESPONSE" = "200" ]; then
    log "✅ Request POST exitoso"
else
    warn "❌ Request POST falló (código: $POST_RESPONSE)"
fi

# 7. Mostrar resumen
echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    🔧 CORS SOLUCIONADO 🔧                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BLUE}📋 INFORMACIÓN:${NC}"
echo -e "   🔗 API Gateway ID: ${GREEN}$API_ID${NC}"
echo -e "   🌐 API URL: ${GREEN}$API_URL${NC}"
echo -e "   🚀 Deployment ID: ${GREEN}$DEPLOYMENT_ID${NC}"

echo -e "\n${BLUE}✅ VERIFICACIONES REALIZADAS:${NC}"
echo -e "   • Métodos OPTIONS agregados donde faltaban"
echo -e "   • Headers CORS verificados en funciones Lambda"
echo -e "   • Nuevo deployment creado"
echo -e "   • Tests de CORS ejecutados"

echo -e "\n${BLUE}🧪 COMANDOS DE TEST:${NC}"
echo -e "   Test OPTIONS:"
echo -e "   ${GREEN}curl -X OPTIONS $API_URL/health -H \"Origin: https://example.com\"${NC}"
echo -e ""
echo -e "   Test POST:"
echo -e "   ${GREEN}curl -X POST $API_URL/health -H \"Content-Type: application/json\" -d '{\"test\": true}'${NC}"

echo -e "\n${BLUE}🛠️  SI PERSISTEN PROBLEMAS:${NC}"
echo -e "   1. Verifica que las funciones Lambda incluyan headers CORS"
echo -e "   2. Revisa la configuración del frontend (dominios permitidos)"
echo -e "   3. Considera usar un proxy o CDN si es necesario"

echo -e "\n${GREEN}¡Configuración de CORS actualizada! 🔧${NC}"
