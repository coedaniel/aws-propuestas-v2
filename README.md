# AWS Propuestas v2 🚀

Sistema profesional para generar propuestas AWS con IA utilizando Amazon Bedrock. Incluye modo conversación libre y arquitecto AWS especializado para crear documentación completa, diagramas y estimaciones de costos.

## 🌟 Características Principales

### 🤖 Dual Mode AI System
- **Chat Libre**: Conversación abierta con modelos de Amazon Bedrock
- **Arquitecto AWS**: Modo guiado para generar propuestas profesionales completas

### 🎯 Modelos de IA Soportados
- **Claude 3.5 Sonnet** - Análisis avanzado y documentación
- **Claude 3 Haiku** - Respuestas rápidas y eficientes
- **Amazon Nova Pro** - Modelo multimodal de Amazon
- **Amazon Titan** - Modelos fundacionales de AWS

### 📋 Generación Automática de Documentos
- **Documentos Word** - Propuestas ejecutivas profesionales
- **Scripts CloudFormation** - Automatización de despliegue
- **Diagramas SVG/PNG** - Arquitecturas visuales
- **Archivos Draw.io** - Diagramas editables
- **Estimaciones de Costos** - CSV/Excel con precios AWS
- **Guías de Calculadora** - Instrucciones para AWS Pricing Calculator

## 🏗️ Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Next.js App  │────│  API Gateway    │────│  Lambda Functions│
│   (Frontend)    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │   DynamoDB      │    │  Amazon Bedrock │
                       │   (Sessions)    │    │   (AI Models)   │
                       └─────────────────┘    └─────────────────┘
                                                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │      S3         │    │   CloudWatch    │
                       │  (Documents)    │    │    (Logs)       │
                       └─────────────────┘    └─────────────────┘
```

## 🚀 Instalación y Despliegue

### Prerrequisitos

1. **AWS CLI** configurado con credenciales apropiadas
2. **AWS SAM CLI** instalado
3. **Node.js** 18+ y npm
4. **Permisos AWS** para Bedrock, Lambda, DynamoDB, S3, CloudFormation

### Instalación Automática

```bash
# Clonar el repositorio
git clone <repository-url>
cd aws-propuestas-v2

# Ejecutar setup completo (instala, despliega backend y configura frontend)
./scripts/setup.sh [environment] [region]

# Ejemplo:
./scripts/setup.sh prod us-east-1
```

### Instalación Manual

```bash
# 1. Instalar dependencias
npm install

# 2. Desplegar backend
./scripts/deploy-backend.sh prod us-east-1

# 3. Configurar variables de entorno
# El script creará automáticamente .env.local con las URLs correctas

# 4. Construir frontend
npm run build

# 5. Iniciar en desarrollo
npm run dev
```

## 🔧 Configuración

### Variables de Entorno

El archivo `.env.local` se crea automáticamente durante el setup:

```env
NEXT_PUBLIC_API_URL=https://your-api-gateway-url
NEXT_PUBLIC_REGION=us-east-1
NEXT_PUBLIC_ENVIRONMENT=prod
```

### Configuración AWS

Asegúrate de tener los siguientes permisos en tu cuenta AWS:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:ListFoundationModels",
        "dynamodb:*",
        "s3:*",
        "lambda:*",
        "apigateway:*",
        "cloudformation:*",
        "iam:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## 📖 Uso del Sistema

### Modo Chat Libre

1. Selecciona "Chat Libre" en la página principal
2. Elige tu modelo de IA preferido
3. Inicia conversación libre sobre AWS, arquitecturas, mejores prácticas
4. Ideal para consultas rápidas y brainstorming

### Modo Arquitecto AWS

1. Selecciona "Arquitecto AWS" en la página principal
2. El sistema te guiará paso a paso:
   - **Nombre del proyecto**
   - **Tipo de solución** (integral vs servicio específico)
   - **Requerimientos técnicos**
   - **Especificaciones detalladas**

3. **Para Servicios Rápidos**:
   - Catálogo de servicios comunes (EC2, RDS, S3, etc.)
   - Preguntas mínimas necesarias
   - Generación automática de documentos

4. **Para Soluciones Integrales**:
   - Entrevista guiada completa
   - Análisis de requerimientos
   - Arquitectura compleja
   - Documentación ejecutiva

### Documentos Generados

El sistema genera automáticamente:

- **📄 Propuesta Ejecutiva** (Word) - Documento profesional listo para cliente
- **⚙️ Script CloudFormation** - Automatización de despliegue
- **🎨 Diagramas de Arquitectura** - SVG, PNG y Draw.io editables
- **💰 Estimación de Costos** - Excel/CSV con precios AWS actualizados
- **📊 Tabla de Actividades** - Plan de implementación detallado
- **🧮 Guía de Calculadora** - Instrucciones para AWS Pricing Calculator

## 🛠️ Desarrollo

### Estructura del Proyecto

```
aws-propuestas-v2/
├── app/                    # Next.js App Router
│   ├── api/               # API Routes
│   ├── chat/              # Chat Libre pages
│   ├── arquitecto/        # Arquitecto AWS pages
│   └── globals.css        # Estilos globales
├── components/            # Componentes React
│   ├── ui/               # Componentes UI base
│   ├── chat/             # Componentes de chat
│   └── arquitecto/       # Componentes del arquitecto
├── lib/                  # Utilidades y configuración
│   ├── aws/              # Clientes AWS (Bedrock, DynamoDB, S3)
│   ├── types/            # Definiciones TypeScript
│   └── utils.ts          # Utilidades generales
├── store/                # Estado global (Zustand)
├── infrastructure/       # CloudFormation/SAM templates
├── scripts/              # Scripts de despliegue
└── docs/                 # Documentación adicional
```

### Scripts Disponibles

```bash
# Desarrollo
npm run dev          # Servidor de desarrollo
npm run build        # Construir para producción
npm run start        # Servidor de producción
npm run lint         # Linter
npm run type-check   # Verificación de tipos

# Despliegue
./scripts/setup.sh              # Setup completo
./scripts/deploy-backend.sh     # Solo backend
```

### Agregar Nuevos Modelos

Para agregar soporte a nuevos modelos de Bedrock:

1. Actualizar `lib/aws/bedrock.ts`
2. Agregar configuración en `lib/types/chat.ts`
3. Actualizar UI en componentes de selección de modelo

## 🔍 Monitoreo y Logs

### CloudWatch Logs

```bash
# Ver logs de Lambda
aws logs tail /aws/lambda/aws-propuestas-chat-function --follow

# Ver logs de API Gateway
aws logs tail /aws/apigateway/aws-propuestas-api --follow
```

### Métricas

- **Invocaciones Lambda**: Número de requests procesados
- **Errores**: Rate de errores por función
- **Duración**: Tiempo de respuesta promedio
- **Costos Bedrock**: Tokens consumidos por modelo

## 🚨 Troubleshooting

### Problemas Comunes

1. **Error de permisos Bedrock**:
   ```bash
   # Verificar acceso a modelos
   aws bedrock list-foundation-models --region us-east-1
   ```

2. **Error de CORS**:
   - Verificar configuración en API Gateway
   - Revisar headers en `app/api/chat/route.ts`

3. **Error de DynamoDB**:
   ```bash
   # Verificar tablas
   aws dynamodb list-tables --region us-east-1
   ```

4. **Modelos no disponibles**:
   - Algunos modelos requieren solicitud de acceso en AWS Console
   - Ir a Bedrock > Model Access y solicitar acceso

### Logs de Debug

Activar logs detallados:

```env
# En .env.local
NEXT_PUBLIC_DEBUG=true
```

## 📊 Costos Estimados

### Componentes de Costo

- **Amazon Bedrock**: $0.003-$0.015 por 1K tokens (varía por modelo)
- **Lambda**: $0.20 por 1M requests + $0.0000166667 por GB-segundo
- **DynamoDB**: $0.25 por GB almacenado + $1.25 por millón de requests
- **S3**: $0.023 por GB almacenado + $0.0004 por 1K requests
- **API Gateway**: $3.50 por millón de requests

### Estimación Mensual (uso moderado)

- **10,000 conversaciones/mes**: ~$15-30 USD
- **100,000 conversaciones/mes**: ~$150-300 USD

## 🤝 Contribución

1. Fork el repositorio
2. Crear branch para feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 🆘 Soporte

- **Issues**: Reportar bugs y solicitar features en GitHub Issues
- **Documentación**: Ver carpeta `docs/` para guías detalladas
- **AWS Support**: Para problemas específicos de servicios AWS

## 🎯 Roadmap

### v2.1 (Próximo)
- [ ] Soporte para más modelos de Bedrock
- [ ] Integración con AWS Cost Explorer
- [ ] Templates personalizables
- [ ] Modo colaborativo multi-usuario

### v2.2 (Futuro)
- [ ] Integración con AWS Organizations
- [ ] Reportes de compliance
- [ ] API pública para integraciones
- [ ] Mobile app companion

---

**AWS Propuestas v2** - Construido con ❤️ usando Next.js, Amazon Bedrock y AWS Serverless

🚀 **¡Listo para crear propuestas AWS profesionales con IA!**
