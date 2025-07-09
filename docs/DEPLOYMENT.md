# Guía de Despliegue - AWS Propuestas v2

Esta guía te llevará paso a paso para desplegar AWS Propuestas v2 en tu cuenta de AWS.

## 📋 Prerrequisitos

### 1. Herramientas Requeridas

```bash
# Verificar instalaciones
aws --version          # AWS CLI v2.x
sam --version          # SAM CLI v1.x
node --version         # Node.js v18+
npm --version          # npm v8+
```

### 2. Configuración AWS

```bash
# Configurar AWS CLI
aws configure

# Verificar configuración
aws sts get-caller-identity
```

### 3. Permisos IAM Requeridos

Tu usuario/rol debe tener permisos para:

- **Amazon Bedrock**: `bedrock:InvokeModel`, `bedrock:ListFoundationModels`
- **AWS Lambda**: `lambda:*`
- **Amazon DynamoDB**: `dynamodb:*`
- **Amazon S3**: `s3:*`
- **API Gateway**: `apigateway:*`
- **CloudFormation**: `cloudformation:*`
- **IAM**: `iam:CreateRole`, `iam:AttachRolePolicy`, etc.
- **CloudWatch**: `logs:*`

## 🚀 Despliegue Automático (Recomendado)

### Opción 1: Setup Completo

```bash
# Clonar repositorio
git clone <repository-url>
cd aws-propuestas-v2

# Ejecutar setup automático
./scripts/setup.sh prod us-east-1
```

Este script:
1. ✅ Instala dependencias npm
2. ✅ Despliega backend con SAM
3. ✅ Configura variables de entorno
4. ✅ Construye frontend
5. ✅ Muestra información de despliegue

### Opción 2: Solo Backend

```bash
# Solo desplegar backend
./scripts/deploy-backend.sh prod us-east-1
```

## 🔧 Despliegue Manual

### Paso 1: Preparar Proyecto

```bash
# Instalar dependencias
npm install

# Verificar estructura
ls -la
```

### Paso 2: Desplegar Backend

```bash
# Construir aplicación SAM
sam build --template-file infrastructure/template.yaml

# Desplegar a AWS
sam deploy \
    --stack-name aws-propuestas-v2-prod \
    --capabilities CAPABILITY_IAM \
    --region us-east-1 \
    --resolve-s3 \
    --no-confirm-changeset \
    --parameter-overrides Environment=prod
```

### Paso 3: Obtener URLs de API

```bash
# Obtener URL de API Gateway
aws cloudformation describe-stacks \
    --stack-name aws-propuestas-v2-prod \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text
```

### Paso 4: Configurar Frontend

```bash
# Crear archivo de configuración
cat > .env.local << EOF
NEXT_PUBLIC_API_URL=https://your-api-url.execute-api.us-east-1.amazonaws.com/prod
NEXT_PUBLIC_REGION=us-east-1
NEXT_PUBLIC_ENVIRONMENT=prod
EOF
```

### Paso 5: Construir Frontend

```bash
# Construir para producción
npm run build

# Probar localmente
npm run start
```

## 🌐 Despliegue de Frontend

### Opción 1: AWS Amplify (Recomendado)

1. **Subir código a GitHub**:
   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

2. **Configurar Amplify**:
   - Ir a AWS Amplify Console
   - Conectar repositorio GitHub
   - Configurar build settings:
     ```yaml
     version: 1
     frontend:
       phases:
         preBuild:
           commands:
             - npm ci
         build:
           commands:
             - npm run build
       artifacts:
         baseDirectory: .next
         files:
           - '**/*'
       cache:
         paths:
           - node_modules/**/*
     ```

3. **Variables de Entorno en Amplify**:
   - `NEXT_PUBLIC_API_URL`: URL de tu API Gateway
   - `NEXT_PUBLIC_REGION`: us-east-1
   - `NEXT_PUBLIC_ENVIRONMENT`: prod

### Opción 2: Amazon S3 + CloudFront

```bash
# Exportar aplicación estática
npm run build
npm run export

# Subir a S3
aws s3 sync out/ s3://your-bucket-name --delete

# Invalidar CloudFront
aws cloudfront create-invalidation \
    --distribution-id YOUR_DISTRIBUTION_ID \
    --paths "/*"
```

### Opción 3: Amazon ECS/Fargate

```bash
# Crear Dockerfile (ya incluido)
docker build -t aws-propuestas-v2 .

# Subir a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

docker tag aws-propuestas-v2:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/aws-propuestas-v2:latest

docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/aws-propuestas-v2:latest
```

## 🔍 Verificación del Despliegue

### 1. Verificar Backend

```bash
# Probar API de chat
curl -X POST https://your-api-url/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [{"role": "user", "content": "Hola!"}],
    "modelId": "anthropic.claude-3-haiku-20240307-v1:0"
  }'
```

### 2. Verificar Recursos AWS

```bash
# Verificar tablas DynamoDB
aws dynamodb list-tables --region us-east-1

# Verificar bucket S3
aws s3 ls

# Verificar funciones Lambda
aws lambda list-functions --region us-east-1
```

### 3. Verificar Logs

```bash
# Ver logs de Lambda
aws logs tail /aws/lambda/aws-propuestas-chat-function --follow

# Ver logs de API Gateway
aws logs describe-log-groups --log-group-name-prefix /aws/apigateway/
```

## 🌍 Despliegue Multi-Región

### Configuración para Alta Disponibilidad

```bash
# Desplegar en múltiples regiones
./scripts/deploy-backend.sh prod us-east-1
./scripts/deploy-backend.sh prod us-west-2
./scripts/deploy-backend.sh prod eu-west-1
```

### Route 53 para Failover

```yaml
# Configurar Route 53 Health Checks
PrimaryEndpoint:
  Type: AWS::Route53::RecordSet
  Properties:
    HostedZoneId: !Ref HostedZone
    Name: api.yourapp.com
    Type: A
    SetIdentifier: primary
    Failover: PRIMARY
    AliasTarget:
      DNSName: !GetAtt ApiGateway.RegionalDomainName
      HostedZoneId: !GetAtt ApiGateway.RegionalHostedZoneId
```

## 🔒 Configuración de Seguridad

### 1. Habilitar WAF

```bash
# Crear Web ACL
aws wafv2 create-web-acl \
    --name aws-propuestas-waf \
    --scope REGIONAL \
    --default-action Allow={} \
    --region us-east-1
```

### 2. Configurar API Keys

```bash
# Crear API Key
aws apigateway create-api-key \
    --name aws-propuestas-api-key \
    --enabled
```

### 3. Configurar CORS

```javascript
// Ya configurado en app/api/chat/route.ts
headers: {
  'Access-Control-Allow-Origin': 'https://yourdomain.com',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
}
```

## 📊 Monitoreo y Alertas

### CloudWatch Dashboards

```bash
# Crear dashboard personalizado
aws cloudwatch put-dashboard \
    --dashboard-name "AWS-Propuestas-v2" \
    --dashboard-body file://monitoring/dashboard.json
```

### Alertas CloudWatch

```bash
# Crear alarma para errores
aws cloudwatch put-metric-alarm \
    --alarm-name "AWS-Propuestas-High-Error-Rate" \
    --alarm-description "High error rate in Lambda functions" \
    --metric-name Errors \
    --namespace AWS/Lambda \
    --statistic Sum \
    --period 300 \
    --threshold 10 \
    --comparison-operator GreaterThanThreshold
```

## 🔄 Actualizaciones

### Actualizar Backend

```bash
# Actualizar código
git pull origin main

# Re-desplegar
sam build && sam deploy --no-confirm-changeset
```

### Actualizar Frontend

```bash
# Si usas Amplify, solo hacer push
git push origin main

# Si usas S3, re-construir y subir
npm run build
aws s3 sync out/ s3://your-bucket-name --delete
```

## 🚨 Troubleshooting

### Problemas Comunes

1. **Error de permisos Bedrock**:
   ```bash
   # Verificar acceso a modelos
   aws bedrock list-foundation-models --region us-east-1
   ```

2. **Error de CORS**:
   - Verificar configuración en API Gateway
   - Revisar headers en route handlers

3. **Error de DynamoDB**:
   ```bash
   # Verificar tablas
   aws dynamodb describe-table --table-name aws-propuestas-chat-sessions-prod
   ```

4. **Error de memoria Lambda**:
   - Aumentar memoria en template.yaml
   - Optimizar código para reducir uso de memoria

### Logs de Debug

```bash
# Habilitar logs detallados
export NEXT_PUBLIC_DEBUG=true

# Ver logs en tiempo real
aws logs tail /aws/lambda/aws-propuestas-chat-function --follow
```

## 📞 Soporte

- **Documentación**: Ver `/docs` para guías detalladas
- **Issues**: Reportar en GitHub Issues
- **AWS Support**: Para problemas específicos de servicios AWS

---

¡Tu AWS Propuestas v2 está listo para generar propuestas profesionales con IA! 🚀
