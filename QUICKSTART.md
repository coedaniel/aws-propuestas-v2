# 🚀 Quick Start - AWS Propuestas v2

¡Despliega tu sistema de propuestas AWS con IA en menos de 10 minutos!

## ⚡ Despliegue en 3 Pasos

### 1️⃣ Preparar Entorno

```bash
# Verificar prerrequisitos
aws --version    # Debe ser v2.x
sam --version    # Debe estar instalado
node --version   # Debe ser v18+

# Configurar AWS (si no está configurado)
aws configure
```

### 2️⃣ Desplegar Automáticamente

```bash
# Clonar y desplegar todo de una vez
git clone <repository-url>
cd aws-propuestas-v2

# 🎯 UN SOLO COMANDO PARA TODO
./scripts/setup.sh prod us-east-1
```

### 3️⃣ ¡Listo para Usar!

```bash
# Iniciar aplicación
npm run dev

# Abrir en navegador
open http://localhost:3000
```

## 🎯 ¿Qué Hace el Script de Setup?

El comando `./scripts/setup.sh` ejecuta automáticamente:

1. ✅ **Instala dependencias** npm
2. ✅ **Despliega backend** (Lambda, DynamoDB, S3, API Gateway)
3. ✅ **Configura variables** de entorno automáticamente
4. ✅ **Construye frontend** para producción
5. ✅ **Muestra URLs** y configuración final

## 🔧 Personalizar Despliegue

### Cambiar Región

```bash
# Desplegar en otra región
./scripts/setup.sh prod eu-west-1
```

### Cambiar Ambiente

```bash
# Desplegar ambiente de desarrollo
./scripts/setup.sh dev us-east-1
```

### Solo Backend

```bash
# Solo desplegar backend
./scripts/deploy-backend.sh prod us-east-1
```

## 🧪 Verificar Despliegue

```bash
# Verificar que todo funciona
./scripts/verify-deployment.sh prod us-east-1
```

## 🎨 Usar la Aplicación

### Modo Chat Libre
1. Ir a http://localhost:3000
2. Seleccionar "Chat Libre"
3. Elegir modelo de IA (Claude, Nova, Titan)
4. ¡Chatear sobre AWS!

### Modo Arquitecto AWS
1. Seleccionar "Arquitecto AWS"
2. Seguir el flujo guiado
3. Responder preguntas sobre tu proyecto
4. ¡Recibir propuesta completa con documentos!

## 📋 Lo Que Obtienes

### 🤖 Modelos de IA Disponibles
- **Claude 3.5 Sonnet** - Análisis avanzado
- **Claude 3 Haiku** - Respuestas rápidas
- **Amazon Nova Pro** - Multimodal
- **Amazon Titan** - Fundacional AWS

### 📄 Documentos Generados
- **Propuesta Ejecutiva** (Word)
- **Scripts CloudFormation**
- **Diagramas de Arquitectura** (SVG, PNG, Draw.io)
- **Estimaciones de Costos** (Excel/CSV)
- **Plan de Implementación**
- **Guía de Calculadora AWS**

### 🏗️ Infraestructura Desplegada
- **API Gateway** - Endpoints REST
- **Lambda Functions** - Lógica de negocio
- **DynamoDB** - Almacenamiento de sesiones
- **S3 Bucket** - Documentos generados
- **CloudWatch** - Logs y monitoreo

## 🚨 Solución de Problemas

### Error: "AWS CLI not configured"
```bash
aws configure
# Ingresar Access Key, Secret Key, Region
```

### Error: "SAM CLI not found"
```bash
# Instalar SAM CLI
pip install aws-sam-cli
# o seguir: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
```

### Error: "Bedrock access denied"
```bash
# Ir a AWS Console > Bedrock > Model Access
# Solicitar acceso a los modelos necesarios
```

### Error: "Stack already exists"
```bash
# Eliminar stack existente
aws cloudformation delete-stack --stack-name aws-propuestas-v2-prod --region us-east-1

# Esperar y volver a desplegar
./scripts/setup.sh prod us-east-1
```

## 🌐 Desplegar Frontend a Producción

### Opción 1: AWS Amplify (Recomendado)
```bash
# Subir a GitHub
git add .
git commit -m "Deploy to production"
git push origin main

# Conectar en AWS Amplify Console
# Amplify detectará automáticamente Next.js
```

### Opción 2: Vercel
```bash
npm install -g vercel
vercel --prod
```

### Opción 3: Docker
```bash
docker build -t aws-propuestas-v2 .
docker run -p 3000:3000 aws-propuestas-v2
```

## 💰 Costos Estimados

### Uso Ligero (1,000 conversaciones/mes)
- **Bedrock**: ~$3-5 USD
- **Lambda**: ~$1 USD
- **DynamoDB**: ~$1 USD
- **S3**: ~$0.50 USD
- **API Gateway**: ~$3.50 USD
- **Total**: ~$9-11 USD/mes

### Uso Moderado (10,000 conversaciones/mes)
- **Total**: ~$50-80 USD/mes

### Uso Alto (100,000 conversaciones/mes)
- **Total**: ~$300-500 USD/mes

## 📞 Soporte y Recursos

- **📖 Documentación Completa**: Ver `README.md`
- **🔧 Guía de Despliegue**: Ver `docs/DEPLOYMENT.md`
- **🐛 Reportar Issues**: GitHub Issues
- **💬 Discusiones**: GitHub Discussions

## 🎯 Próximos Pasos

1. **Personalizar**: Modificar prompts y flujos según tus necesidades
2. **Integrar**: Conectar con tus sistemas existentes
3. **Escalar**: Configurar multi-región para alta disponibilidad
4. **Monitorear**: Configurar alertas y dashboards
5. **Optimizar**: Ajustar costos y rendimiento

---

## 🎉 ¡Felicidades!

¡Tu AWS Propuestas v2 está listo para generar propuestas profesionales con IA!

**Tiempo total de setup**: ~5-10 minutos  
**Próximo paso**: Abrir http://localhost:3000 y crear tu primera propuesta

---

**¿Necesitas ayuda?** Revisa la documentación completa en `README.md` o abre un issue en GitHub.

🚀 **¡Happy Building!**
