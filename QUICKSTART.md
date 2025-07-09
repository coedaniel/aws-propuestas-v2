# 🚀 AWS Propuestas v2 - Guía de Inicio Rápido

## Despliegue en 3 Pasos

### 1. Verificar Prerrequisitos ✅
```bash
curl -fsSL https://raw.githubusercontent.com/tu-usuario/aws-propuestas-v2/main/scripts/check-prerequisites.sh | bash
```

**Prerrequisitos mínimos:**
- AWS CLI configurado
- SAM CLI instalado
- Node.js 18+
- Credenciales AWS con permisos de administrador

### 2. Despliegue Automático 🚀
```bash
curl -fsSL https://raw.githubusercontent.com/tu-usuario/aws-propuestas-v2/main/scripts/deploy.sh | bash
```

**O clonación manual:**
```bash
git clone https://github.com/tu-usuario/aws-propuestas-v2.git
cd aws-propuestas-v2
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### 3. Habilitar Modelos de Bedrock 🤖
1. Ve a [Amazon Bedrock Console](https://console.aws.amazon.com/bedrock/home#/modelaccess)
2. Habilita estos modelos:
   - ✅ `amazon.nova-pro-v1:0`
   - ✅ `anthropic.claude-3-haiku-20240307-v1:0`

## Verificación Rápida 🧪

### Test del Backend
```bash
# Health check
curl https://tu-api.execute-api.us-east-1.amazonaws.com/prod/health

# Test arquitecto
curl -X POST https://tu-api.execute-api.us-east-1.amazonaws.com/prod/arquitecto \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hola"}]}'
```

### Test del Frontend
1. Abre la URL de Amplify (mostrada al final del despliegue)
2. Prueba el chat básico
3. Prueba el modo arquitecto

## Solución de Problemas 🔧

### Error de CORS
```bash
./scripts/fix-cors.sh
```

### Error "AccessDeniedException"
```bash
# Verificar modelos habilitados
aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?contains(modelId, `nova-pro`) || contains(modelId, `claude-3-haiku`)]'
```

### Redesplegar Solo Frontend
```bash
./scripts/deploy-frontend.sh
```

### Redesplegar Solo Backend
```bash
cd infrastructure
sam build && sam deploy --no-confirm-changeset
```

### Ver Logs en Tiempo Real
```bash
# Logs de arquitecto
aws logs tail /aws/lambda/aws-propuestas-arquitecto-prod --follow

# Logs de chat
aws logs tail /aws/lambda/aws-propuestas-chat-prod --follow

# Logs de API Gateway
aws logs tail /aws/apigateway/aws-propuestas-v2-prod --follow
```

## Estructura del Proyecto 📁

```
aws-propuestas-v2/
├── 🎨 app/                    # Frontend Next.js
├── 🔧 components/            # Componentes React
├── ⚡ lambda/               # Funciones Lambda
├── 🏗️ infrastructure/       # Templates SAM
├── 📜 scripts/              # Scripts de despliegue
└── 📖 docs/                 # Documentación
```

## URLs Importantes 🔗

- **API Health**: `https://tu-api.execute-api.us-east-1.amazonaws.com/prod/health`
- **Bedrock Console**: https://console.aws.amazon.com/bedrock/
- **CloudWatch Logs**: https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups
- **API Gateway Console**: https://console.aws.amazon.com/apigateway/
- **Lambda Console**: https://console.aws.amazon.com/lambda/

## Comandos Útiles 💻

### Desarrollo Local
```bash
# Instalar dependencias
npm install

# Servidor de desarrollo
npm run dev

# Build de producción
npm run build

# Test local de Lambda
cd infrastructure
sam local invoke ArquitectoFunction --event events/test-event.json
```

### Monitoreo
```bash
# Ver métricas de Lambda
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=aws-propuestas-arquitecto-prod \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum

# Ver costos
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-02 \
  --granularity DAILY \
  --metrics BlendedCost
```

### Limpieza
```bash
# Eliminar stack completo
aws cloudformation delete-stack --stack-name aws-propuestas-v2-prod

# Eliminar bucket S3 (si existe)
aws s3 rb s3://aws-propuestas-documents-prod-* --force
```

## Costos Estimados 💰

| Servicio | Uso Mensual | Costo |
|----------|-------------|-------|
| Lambda | 10K invocaciones | $0.20 |
| API Gateway | 10K requests | $0.35 |
| DynamoDB | 1GB storage | $0.25 |
| S3 | 1GB storage | $0.02 |
| Bedrock Nova Pro | 1M tokens | $8.00 |
| **Total** | | **~$8.82** |

## Soporte y Recursos 🆘

- 📖 [README Completo](README.md)
- 🐛 [Reportar Issues](https://github.com/tu-usuario/aws-propuestas-v2/issues)
- 💬 [Discusiones](https://github.com/tu-usuario/aws-propuestas-v2/discussions)
- 📧 Email: tu-email@ejemplo.com

## Próximos Pasos 🎯

1. **Personalizar**: Modifica los prompts en `lambda/arquitecto/app.py`
2. **Extender**: Agrega nuevos endpoints o funcionalidades
3. **Monitorear**: Configura alertas en CloudWatch
4. **Optimizar**: Ajusta memoria y timeout de Lambda según uso
5. **Escalar**: Considera usar DynamoDB On-Demand para cargas variables

---

⭐ **¡Si este proyecto te ayuda, dale una estrella en GitHub!** ⭐
