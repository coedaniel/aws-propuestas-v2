#!/bin/bash

# 🚀 AWS Propuestas v2 - Script de Despliegue Automático
# Este script despliega todo el sistema con un solo comando

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
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
║        🚀 AWS Propuestas v2 - Despliegue Automático         ║
║                                                              ║
║     Sistema Profesional de Propuestas AWS con IA            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Variables
PROJECT_NAME="aws-propuestas-v2"
STACK_NAME="aws-propuestas-v2-prod"
REGION="us-east-1"
ENVIRONMENT="prod"

log "Iniciando despliegue de $PROJECT_NAME..."

# 1. Verificar prerrequisitos
log "Verificando prerrequisitos..."

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    error "AWS CLI no está instalado. Instálalo desde: https://aws.amazon.com/cli/"
fi

# Verificar SAM CLI
if ! command -v sam &> /dev/null; then
    error "AWS SAM CLI no está instalado. Instálalo desde: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
fi

# Verificar Node.js
if ! command -v node &> /dev/null; then
    error "Node.js no está instalado. Instálalo desde: https://nodejs.org/"
fi

# Verificar credenciales AWS
if ! aws sts get-caller-identity &> /dev/null; then
    error "Credenciales AWS no configuradas. Ejecuta: aws configure"
fi

log "✅ Prerrequisitos verificados"

# 2. Clonar repositorio si no existe
if [ ! -d "$PROJECT_NAME" ]; then
    log "Clonando repositorio..."
    git clone https://github.com/tu-usuario/$PROJECT_NAME.git
    cd $PROJECT_NAME
else
    log "Repositorio ya existe, actualizando..."
    cd $PROJECT_NAME
    git pull origin main
fi

# 3. Instalar dependencias del frontend
log "Instalando dependencias del frontend..."
npm install

# 4. Desplegar backend (Lambda + API Gateway)
log "Desplegando backend serverless..."
cd infrastructure

# Build SAM application
log "Construyendo aplicación SAM..."
sam build

# Deploy with guided parameters for first time
if ! aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
    log "Primera vez desplegando. Configurando parámetros..."
    sam deploy \
        --stack-name $STACK_NAME \
        --region $REGION \
        --capabilities CAPABILITY_IAM \
        --parameter-overrides Environment=$ENVIRONMENT \
        --confirm-changeset \
        --resolve-s3
else
    log "Stack existe, actualizando..."
    sam deploy --no-confirm-changeset
fi

# 5. Obtener URL del API Gateway
log "Obteniendo URL del API Gateway..."
API_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

if [ -z "$API_URL" ]; then
    error "No se pudo obtener la URL del API Gateway"
fi

log "✅ API Gateway URL: $API_URL"

# 6. Configurar variables de entorno del frontend
log "Configurando variables de entorno del frontend..."
cd ..
cat > .env.local << EOF
NEXT_PUBLIC_API_URL=$API_URL
NEXT_PUBLIC_REGION=$REGION
NEXT_PUBLIC_ENVIRONMENT=$ENVIRONMENT
EOF

# 7. Construir frontend
log "Construyendo frontend Next.js..."
npm run build

# 8. Verificar que el build fue exitoso
if [ ! -d "out" ]; then
    error "Build del frontend falló. Directorio 'out' no encontrado."
fi

log "✅ Frontend construido exitosamente"

# 9. Desplegar frontend en Amplify (opcional)
read -p "¿Deseas desplegar el frontend en AWS Amplify? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Desplegando frontend en AWS Amplify..."
    
    # Verificar si Amplify CLI está instalado
    if ! command -v amplify &> /dev/null; then
        warn "Amplify CLI no está instalado. Instalando..."
        npm install -g @aws-amplify/cli
    fi
    
    # Configurar Amplify si no existe
    if [ ! -f "amplify/.config/project-config.json" ]; then
        log "Configurando Amplify por primera vez..."
        amplify init --yes
    fi
    
    # Desplegar
    amplify publish --yes
    
    log "✅ Frontend desplegado en Amplify"
else
    info "Frontend no desplegado en Amplify. Puedes usar el directorio 'out' para despliegue manual."
fi

# 10. Verificar despliegue
log "Verificando despliegue..."

# Test health endpoint
HEALTH_URL="$API_URL/health"
if curl -f -s "$HEALTH_URL" > /dev/null; then
    log "✅ Health check exitoso"
else
    warn "Health check falló. Verificando..."
fi

# Test arquitecto endpoint
ARQUITECTO_URL="$API_URL/arquitecto"
TEST_RESPONSE=$(curl -s -X POST "$ARQUITECTO_URL" \
    -H "Content-Type: application/json" \
    -d '{"messages": [{"role": "user", "content": "test"}]}')

if echo "$TEST_RESPONSE" | grep -q "response"; then
    log "✅ Endpoint arquitecto funcionando"
else
    warn "Endpoint arquitecto puede tener problemas"
fi

# 11. Verificar modelos de Bedrock
log "Verificando acceso a modelos de Bedrock..."
if aws bedrock list-foundation-models --region $REGION --query 'modelSummaries[?modelId==`amazon.nova-pro-v1:0`]' --output text | grep -q "amazon.nova-pro-v1:0"; then
    log "✅ Amazon Nova Pro disponible"
else
    warn "Amazon Nova Pro no está disponible. Habilítalo en la consola de Bedrock."
fi

# 12. Mostrar resumen
echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    🎉 DESPLIEGUE EXITOSO 🎉                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BLUE}📋 INFORMACIÓN DEL DESPLIEGUE:${NC}"
echo -e "   🌐 API Gateway URL: ${GREEN}$API_URL${NC}"
echo -e "   📦 Stack Name: ${GREEN}$STACK_NAME${NC}"
echo -e "   🌍 Region: ${GREEN}$REGION${NC}"
echo -e "   🏷️  Environment: ${GREEN}$ENVIRONMENT${NC}"

echo -e "\n${BLUE}🔗 ENDPOINTS DISPONIBLES:${NC}"
echo -e "   ❤️  Health: ${GREEN}$API_URL/health${NC}"
echo -e "   💬 Chat: ${GREEN}$API_URL/chat${NC}"
echo -e "   🏗️  Arquitecto: ${GREEN}$API_URL/arquitecto${NC}"
echo -e "   📄 Documents: ${GREEN}$API_URL/documents${NC}"

echo -e "\n${BLUE}🛠️  PRÓXIMOS PASOS:${NC}"
echo -e "   1. Habilita modelos de Bedrock en: https://console.aws.amazon.com/bedrock/"
echo -e "   2. Modelos requeridos:"
echo -e "      • amazon.nova-pro-v1:0"
echo -e "      • anthropic.claude-3-haiku-20240307-v1:0"
echo -e "   3. Accede a tu aplicación en el frontend desplegado"

echo -e "\n${BLUE}📊 MONITOREO:${NC}"
echo -e "   📈 CloudWatch Logs: aws logs tail /aws/lambda/aws-propuestas-arquitecto-prod --follow"
echo -e "   💰 Costos: https://console.aws.amazon.com/cost-management/"

echo -e "\n${BLUE}🆘 SOPORTE:${NC}"
echo -e "   📖 README: https://github.com/tu-usuario/$PROJECT_NAME"
echo -e "   🐛 Issues: https://github.com/tu-usuario/$PROJECT_NAME/issues"

echo -e "\n${GREEN}¡Despliegue completado exitosamente! 🚀${NC}"

# Guardar información del despliegue
cat > deployment-info.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "stack_name": "$STACK_NAME",
  "region": "$REGION",
  "environment": "$ENVIRONMENT",
  "api_url": "$API_URL",
  "endpoints": {
    "health": "$API_URL/health",
    "chat": "$API_URL/chat",
    "arquitecto": "$API_URL/arquitecto",
    "documents": "$API_URL/documents"
  }
}
EOF

log "Información del despliegue guardada en deployment-info.json"
