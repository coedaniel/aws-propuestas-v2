# 🚀 AWS Propuestas v2 - Sistema Profesional de Propuestas AWS con IA

Sistema completo para generar propuestas profesionales de AWS utilizando Amazon Nova Pro y arquitectura serverless. Incluye frontend Next.js y backend Lambda con funcionalidades de chat y modo arquitecto especializado.

## ✨ Características

- 🤖 **Chat con IA**: Conversaciones inteligentes con Amazon Nova Pro
- 🏗️ **Modo Arquitecto**: Generación guiada de propuestas AWS profesionales
- 📄 **Generación de Documentos**: CloudFormation, diagramas, costos y documentación
- 🔒 **Seguro**: Permisos IAM configurados correctamente
- ⚡ **Serverless**: Arquitectura completamente serverless en AWS
- 🎨 **UI Moderna**: Interfaz responsive con Tailwind CSS

## 🏗️ Arquitectura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   AWS Amplify   │    │   API Gateway    │    │ Lambda Functions│
│   (Frontend)    │───▶│                  │───▶│                 │
│   Next.js       │    │ /chat            │    │ • Chat Handler  │
│   Static Export │    │ /arquitecto      │    │ • Arquitecto    │
└─────────────────┘    │ /documents       │    │ • Documents     │
                       │ /health          │    │ • Health        │
                       └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   Amazon Nova    │    │   DynamoDB      │
                       │   Pro (Bedrock)  │    │   + S3 Bucket   │
                       └──────────────────┘    └─────────────────┘
```

## 🚀 Despliegue Rápido (Un Click)

### Opción 1: Despliegue Completo Automático

```bash
curl -fsSL https://raw.githubusercontent.com/tu-usuario/aws-propuestas-v2/main/scripts/deploy.sh | bash
```

### Opción 2: Clonación Manual

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/aws-propuestas-v2.git
cd aws-propuestas-v2

# 2. Ejecutar script de despliegue
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## 📋 Prerrequisitos

- ✅ AWS CLI configurado con permisos de administrador
- ✅ AWS SAM CLI instalado
- ✅ Node.js 18+ instalado
- ✅ Modelos de Bedrock habilitados:
  - `amazon.nova-pro-v1:0`
  - `anthropic.claude-3-haiku-20240307-v1:0`

### Verificación Rápida de Prerrequisitos

```bash
# Ejecutar verificación automática
./scripts/check-prerequisites.sh
```

## 🛠️ Instalación Manual (Paso a Paso)

### 1. Backend (Lambda + API Gateway)

```bash
# Desplegar infraestructura serverless
cd infrastructure
sam build
sam deploy --guided

# Configurar variables de entorno
export API_URL=$(aws cloudformation describe-stacks --stack-name aws-propuestas-v2-prod --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' --output text)
```

### 2. Frontend (Amplify)

```bash
# Construir aplicación Next.js
npm install
npm run build

# Desplegar en Amplify
./scripts/deploy-frontend.sh
```

## 🔧 Configuración

### Variables de Entorno

Crear `.env.local`:

```env
NEXT_PUBLIC_API_URL=https://tu-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod
NEXT_PUBLIC_REGION=us-east-1
NEXT_PUBLIC_ENVIRONMENT=prod
```

### Habilitar Modelos de Bedrock

1. Ve a la consola de Amazon Bedrock
2. Navega a "Model access"
3. Habilita los siguientes modelos:
   - Amazon Nova Pro (`amazon.nova-pro-v1:0`)
   - Claude 3 Haiku (`anthropic.claude-3-haiku-20240307-v1:0`)

## 🎯 Uso

### Chat Básico

```javascript
// Ejemplo de llamada al endpoint de chat
const response = await fetch(`${API_URL}/chat`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    messages: [
      { role: 'user', content: 'Hola, necesito ayuda con AWS' }
    ],
    modelId: 'amazon.nova-pro-v1:0'
  })
});
```

### Modo Arquitecto

```javascript
// Ejemplo de llamada al modo arquitecto
const response = await fetch(`${API_URL}/arquitecto`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    messages: [
      { role: 'user', content: 'Necesito una propuesta para migración a AWS' }
    ]
  })
});
```

## 📁 Estructura del Proyecto

```
aws-propuestas-v2/
├── 📁 app/                    # Páginas Next.js
│   ├── page.tsx              # Página principal
│   ├── chat/                 # Página de chat
│   └── arquitecto/           # Página de arquitecto
├── 📁 components/            # Componentes React
├── 📁 lambda/               # Funciones Lambda
│   ├── chat/                # Handler de chat
│   ├── arquitecto/          # Handler de arquitecto
│   └── documents/           # Handler de documentos
├── 📁 infrastructure/       # Templates SAM
│   └── template.yaml        # Infraestructura como código
├── 📁 scripts/             # Scripts de despliegue
│   ├── deploy.sh           # Despliegue completo
│   ├── deploy-frontend.sh  # Solo frontend
│   └── check-prerequisites.sh
└── 📄 README.md            # Este archivo
```

## 🔍 Endpoints de la API

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/health` | GET | Health check del sistema |
| `/chat` | POST | Chat general con IA |
| `/arquitecto` | POST | Modo arquitecto especializado |
| `/documents` | POST/GET | Gestión de documentos |

## 🚨 Solución de Problemas

### Error: "AccessDeniedException"
```bash
# Verificar modelos habilitados en Bedrock
aws bedrock list-foundation-models --region us-east-1
```

### Error: "Function not found"
```bash
# Redesplegar backend
cd infrastructure
sam deploy --no-confirm-changeset
```

### Error de CORS en Frontend
```bash
# Verificar configuración de API Gateway
./scripts/fix-cors.sh
```

## 📊 Monitoreo

### CloudWatch Logs
```bash
# Ver logs de función específica
aws logs tail /aws/lambda/aws-propuestas-arquitecto-prod --follow

# Ver logs de API Gateway
aws logs tail /aws/apigateway/aws-propuestas-v2-prod --follow
```

### Métricas
- **Invocaciones Lambda**: CloudWatch → Lambda → Metrics
- **Errores API Gateway**: CloudWatch → API Gateway → Metrics
- **Costos Bedrock**: Cost Explorer → Service: Amazon Bedrock

## 🔄 Actualizaciones

### Actualizar Backend
```bash
cd infrastructure
sam build
sam deploy --no-confirm-changeset
```

### Actualizar Frontend
```bash
npm run build
./scripts/deploy-frontend.sh
```

## 🧪 Testing

### Test Local del Backend
```bash
# Invocar función localmente
cd infrastructure
sam local invoke ArquitectoFunction --event events/test-event.json
```

### Test del Frontend
```bash
# Servidor de desarrollo
npm run dev
# Abrir http://localhost:3000
```

## 💰 Costos Estimados

| Servicio | Uso Mensual | Costo Estimado |
|----------|-------------|----------------|
| Lambda | 10,000 invocaciones | $0.20 |
| API Gateway | 10,000 requests | $0.35 |
| DynamoDB | 1GB storage | $0.25 |
| S3 | 1GB storage | $0.02 |
| Bedrock Nova Pro | 1M tokens | $8.00 |
| **Total** | | **~$8.82/mes** |

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## 📝 Changelog

### v2.0.0 (Actual)
- ✅ Migración a Amazon Nova Pro
- ✅ Modo arquitecto especializado
- ✅ Frontend Next.js con static export
- ✅ Despliegue automatizado
- ✅ Documentación completa

### v1.0.0
- ✅ Chat básico con Claude
- ✅ Backend Lambda
- ✅ Frontend React básico

## 📄 Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.

## 🆘 Soporte

- 📧 **Email**: tu-email@ejemplo.com
- 💬 **Issues**: [GitHub Issues](https://github.com/tu-usuario/aws-propuestas-v2/issues)
- 📖 **Documentación**: [Wiki del Proyecto](https://github.com/tu-usuario/aws-propuestas-v2/wiki)

---

⭐ **¡Si este proyecto te ayuda, dale una estrella en GitHub!** ⭐
