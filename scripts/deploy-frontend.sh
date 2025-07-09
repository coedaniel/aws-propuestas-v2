#!/bin/bash

# 🎨 AWS Propuestas v2 - Despliegue de Frontend
# Script para desplegar solo el frontend en AWS Amplify

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
║        🎨 AWS Propuestas v2 - Despliegue Frontend           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Variables
PROJECT_NAME="aws-propuestas-v2"
STACK_NAME="aws-propuestas-v2-prod"
REGION="us-east-1"

log "Iniciando despliegue del frontend..."

# 1. Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    error "No se encontró package.json. Ejecuta este script desde el directorio raíz del proyecto."
fi

# 2. Verificar Node.js
if ! command -v node &> /dev/null; then
    error "Node.js no está instalado. Instálalo desde: https://nodejs.org/"
fi

# 3. Obtener URL del API Gateway si existe el stack
log "Verificando backend existente..."
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
    API_URL=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
        --output text)
    
    if [ -n "$API_URL" ]; then
        log "✅ Backend encontrado: $API_URL"
    else
        warn "Backend existe pero no se pudo obtener la URL del API Gateway"
        read -p "Ingresa la URL del API Gateway manualmente: " API_URL
    fi
else
    warn "Stack del backend no encontrado. ¿Deseas continuar con una URL manual?"
    read -p "Ingresa la URL del API Gateway (o presiona Enter para omitir): " API_URL
fi

# 4. Configurar variables de entorno
log "Configurando variables de entorno..."
if [ -n "$API_URL" ]; then
    cat > .env.local << EOF
NEXT_PUBLIC_API_URL=$API_URL
NEXT_PUBLIC_REGION=$REGION
NEXT_PUBLIC_ENVIRONMENT=prod
EOF
    log "✅ Variables de entorno configuradas"
else
    warn "No se configuró URL del API. El frontend funcionará en modo demo."
    cat > .env.local << EOF
NEXT_PUBLIC_API_URL=https://demo-api.example.com
NEXT_PUBLIC_REGION=$REGION
NEXT_PUBLIC_ENVIRONMENT=demo
EOF
fi

# 5. Instalar dependencias
log "Instalando dependencias..."
npm install

# 6. Construir aplicación
log "Construyendo aplicación Next.js..."
npm run build

# Verificar que el build fue exitoso
if [ ! -d "out" ]; then
    error "Build falló. Directorio 'out' no encontrado."
fi

log "✅ Build exitoso. Archivos generados en directorio 'out'"

# 7. Mostrar opciones de despliegue
echo -e "\n${BLUE}🚀 OPCIONES DE DESPLIEGUE:${NC}"
echo -e "1. AWS Amplify (recomendado)"
echo -e "2. S3 + CloudFront"
echo -e "3. Solo generar archivos (manual)"

read -p "Selecciona una opción (1-3): " -n 1 -r
echo

case $REPLY in
    1)
        log "Desplegando en AWS Amplify..."
        
        # Verificar Amplify CLI
        if ! command -v amplify &> /dev/null; then
            log "Instalando Amplify CLI..."
            npm install -g @aws-amplify/cli
        fi
        
        # Inicializar Amplify si no existe
        if [ ! -f "amplify/.config/project-config.json" ]; then
            log "Configurando Amplify por primera vez..."
            amplify init --yes
        fi
        
        # Configurar hosting si no existe
        if [ ! -f "amplify/backend/hosting/amplifyhosting/amplifyhosting-template.json" ]; then
            log "Configurando hosting de Amplify..."
            amplify add hosting
        fi
        
        # Desplegar
        log "Publicando en Amplify..."
        amplify publish --yes
        
        log "✅ Frontend desplegado en AWS Amplify"
        ;;
        
    2)
        log "Desplegando en S3 + CloudFront..."
        
        # Crear bucket S3 único
        BUCKET_NAME="aws-propuestas-v2-frontend-$(date +%s)"
        
        log "Creando bucket S3: $BUCKET_NAME"
        aws s3 mb s3://$BUCKET_NAME --region $REGION
        
        # Configurar bucket para hosting estático
        aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document index.html
        
        # Subir archivos
        log "Subiendo archivos a S3..."
        aws s3 sync out/ s3://$BUCKET_NAME --delete
        
        # Configurar política pública
        cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF
        
        aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json
        rm bucket-policy.json
        
        # URL del sitio web
        WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
        
        log "✅ Frontend desplegado en S3"
        log "🌐 URL: $WEBSITE_URL"
        ;;
        
    3)
        log "Archivos generados en directorio 'out'"
        log "Puedes desplegar manualmente estos archivos en cualquier servidor web"
        ;;
        
    *)
        warn "Opción no válida. Archivos generados en directorio 'out'"
        ;;
esac

# 8. Mostrar resumen
echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  🎉 FRONTEND DESPLEGADO 🎉                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BLUE}📋 INFORMACIÓN DEL DESPLIEGUE:${NC}"
if [ -n "$API_URL" ]; then
    echo -e "   🔗 API Backend: ${GREEN}$API_URL${NC}"
fi
echo -e "   📁 Archivos: ${GREEN}./out/${NC}"
echo -e "   🌍 Region: ${GREEN}$REGION${NC}"

echo -e "\n${BLUE}🔧 ARCHIVOS GENERADOS:${NC}"
echo -e "   📄 index.html - Página principal"
echo -e "   📄 chat.html - Página de chat"
echo -e "   📄 arquitecto.html - Página de arquitecto"
echo -e "   📁 _next/ - Assets de Next.js"

if [ "$REPLY" = "2" ] && [ -n "$WEBSITE_URL" ]; then
    echo -e "\n${BLUE}🌐 ACCESO:${NC}"
    echo -e "   🔗 URL del sitio: ${GREEN}$WEBSITE_URL${NC}"
fi

echo -e "\n${BLUE}🛠️  PRÓXIMOS PASOS:${NC}"
echo -e "   1. Verifica que el backend esté funcionando"
echo -e "   2. Prueba las funcionalidades del frontend"
echo -e "   3. Configura un dominio personalizado (opcional)"

echo -e "\n${BLUE}🔄 ACTUALIZACIONES:${NC}"
echo -e "   Para actualizar el frontend:"
echo -e "   ${GREEN}npm run build && ./scripts/deploy-frontend.sh${NC}"

echo -e "\n${GREEN}¡Frontend desplegado exitosamente! 🎨${NC}"
