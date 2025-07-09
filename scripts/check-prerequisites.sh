#!/bin/bash

# 🔍 AWS Propuestas v2 - Verificador de Prerrequisitos
# Verifica que todos los prerrequisitos estén instalados y configurados

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
CHECKS_PASSED=0
CHECKS_FAILED=0
TOTAL_CHECKS=0

# Función para verificaciones
check() {
    local name="$1"
    local command="$2"
    local install_info="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    printf "%-30s" "$name:"
    
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo -e "${RED}❌ FALTA${NC}"
        if [ -n "$install_info" ]; then
            echo -e "   ${YELLOW}💡 $install_info${NC}"
        fi
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║      🔍 AWS Propuestas v2 - Verificador de Prerrequisitos   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}Verificando prerrequisitos del sistema...${NC}\n"

# 1. Herramientas básicas
echo -e "${BLUE}📦 HERRAMIENTAS BÁSICAS:${NC}"
check "AWS CLI" "command -v aws" "Instalar: https://aws.amazon.com/cli/"
check "SAM CLI" "command -v sam" "Instalar: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
check "Node.js" "command -v node" "Instalar: https://nodejs.org/"
check "NPM" "command -v npm" "Viene con Node.js"
check "Git" "command -v git" "Instalar: https://git-scm.com/"
check "Curl" "command -v curl" "Instalar: apt-get install curl (Ubuntu) o brew install curl (Mac)"

echo ""

# 2. Versiones
echo -e "${BLUE}📋 VERSIONES:${NC}"
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
    echo -e "AWS CLI:                      ${GREEN}v$AWS_VERSION${NC}"
fi

if command -v sam &> /dev/null; then
    SAM_VERSION=$(sam --version | cut -d' ' -f4)
    echo -e "SAM CLI:                      ${GREEN}v$SAM_VERSION${NC}"
fi

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "Node.js:                      ${GREEN}$NODE_VERSION${NC}"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "NPM:                          ${GREEN}v$NPM_VERSION${NC}"
fi

echo ""

# 3. Configuración AWS
echo -e "${BLUE}🔐 CONFIGURACIÓN AWS:${NC}"
check "Credenciales AWS" "aws sts get-caller-identity" "Ejecutar: aws configure"

if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    echo -e "Account ID:                   ${GREEN}$ACCOUNT_ID${NC}"
    echo -e "User/Role:                    ${GREEN}$USER_ARN${NC}"
fi

echo ""

# 4. Permisos AWS
echo -e "${BLUE}🛡️  PERMISOS AWS (verificando servicios clave):${NC}"
check "CloudFormation" "aws cloudformation list-stacks --max-items 1" "Necesario para SAM deploy"
check "Lambda" "aws lambda list-functions --max-items 1" "Necesario para funciones serverless"
check "API Gateway" "aws apigateway get-rest-apis --limit 1" "Necesario para API REST"
check "S3" "aws s3 ls" "Necesario para artifacts de SAM"
check "IAM" "aws iam list-roles --max-items 1" "Necesario para roles de Lambda"
check "DynamoDB" "aws dynamodb list-tables" "Necesario para base de datos"

echo ""

# 5. Bedrock (opcional pero recomendado)
echo -e "${BLUE}🤖 AMAZON BEDROCK:${NC}"
check "Bedrock Access" "aws bedrock list-foundation-models --region us-east-1 --max-items 1" "Habilitar en consola de Bedrock"

if aws bedrock list-foundation-models --region us-east-1 &> /dev/null; then
    echo -e "${BLUE}🔍 Verificando modelos específicos:${NC}"
    
    # Verificar Amazon Nova Pro
    if aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?modelId==`amazon.nova-pro-v1:0`]' --output text | grep -q "amazon.nova-pro-v1:0"; then
        echo -e "Amazon Nova Pro:              ${GREEN}✅ Disponible${NC}"
    else
        echo -e "Amazon Nova Pro:              ${YELLOW}⚠️  No habilitado${NC}"
        echo -e "   ${YELLOW}💡 Habilitar en: https://console.aws.amazon.com/bedrock/home#/modelaccess${NC}"
    fi
    
    # Verificar Claude 3 Haiku
    if aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?modelId==`anthropic.claude-3-haiku-20240307-v1:0`]' --output text | grep -q "anthropic.claude-3-haiku-20240307-v1:0"; then
        echo -e "Claude 3 Haiku:               ${GREEN}✅ Disponible${NC}"
    else
        echo -e "Claude 3 Haiku:               ${YELLOW}⚠️  No habilitado${NC}"
        echo -e "   ${YELLOW}💡 Habilitar en: https://console.aws.amazon.com/bedrock/home#/modelaccess${NC}"
    fi
fi

echo ""

# 6. Herramientas opcionales
echo -e "${BLUE}🔧 HERRAMIENTAS OPCIONALES:${NC}"
check "Amplify CLI" "command -v amplify" "Instalar: npm install -g @aws-amplify/cli"
check "Docker" "command -v docker" "Para SAM local testing"
check "jq" "command -v jq" "Para procesamiento JSON"

echo ""

# Resumen final
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        📊 RESUMEN                            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "Total de verificaciones: ${BLUE}$TOTAL_CHECKS${NC}"
echo -e "Exitosas: ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Fallidas: ${RED}$CHECKS_FAILED${NC}"

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ¡Todos los prerrequisitos están listos!${NC}"
    echo -e "${GREEN}Puedes proceder con el despliegue ejecutando:${NC}"
    echo -e "${BLUE}./scripts/deploy.sh${NC}"
elif [ $CHECKS_FAILED -le 3 ]; then
    echo -e "\n${YELLOW}⚠️  Algunos prerrequisitos opcionales faltan${NC}"
    echo -e "${YELLOW}El despliegue básico debería funcionar, pero algunas funciones pueden estar limitadas.${NC}"
    echo -e "${BLUE}Puedes proceder con: ./scripts/deploy.sh${NC}"
else
    echo -e "\n${RED}❌ Faltan prerrequisitos críticos${NC}"
    echo -e "${RED}Por favor, instala las herramientas faltantes antes de continuar.${NC}"
    exit 1
fi

echo -e "\n${BLUE}📚 RECURSOS ÚTILES:${NC}"
echo -e "• AWS CLI: https://aws.amazon.com/cli/"
echo -e "• SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
echo -e "• Node.js: https://nodejs.org/"
echo -e "• Bedrock Console: https://console.aws.amazon.com/bedrock/"
echo -e "• Documentación: https://github.com/tu-usuario/aws-propuestas-v2"

echo -e "\n${GREEN}✨ ¡Listo para desplegar AWS Propuestas v2! ✨${NC}"
