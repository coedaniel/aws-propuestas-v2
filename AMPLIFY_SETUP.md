# 🚀 Configuración de AWS Amplify para AWS Propuestas v2

## Paso a Paso para Desplegar en AWS Amplify

### 1️⃣ **Acceder a AWS Amplify Console**

1. Ve a la [AWS Amplify Console](https://console.aws.amazon.com/amplify/home?region=us-east-1)
2. Haz clic en **"New app"** > **"Host web app"**

### 2️⃣ **Conectar Repositorio GitHub**

1. Selecciona **"GitHub"** como proveedor
2. Haz clic en **"Connect branch"**
3. Autoriza AWS Amplify para acceder a tu GitHub
4. Selecciona el repositorio: **`coedaniel/aws-propuestas-v2`**
5. Selecciona la rama: **`main`**
6. Haz clic en **"Next"**

### 3️⃣ **Configurar Build Settings**

La configuración de build ya está incluida en el archivo `amplify.yml`. Amplify lo detectará automáticamente.

**Si necesitas configurar manualmente:**
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

### 4️⃣ **Configurar Variables de Entorno**

En la sección **"Environment variables"**, agrega:

| Variable | Valor |
|----------|-------|
| `NEXT_PUBLIC_API_URL` | `https://v13oiy941a.execute-api.us-east-1.amazonaws.com/prod` |
| `NEXT_PUBLIC_REGION` | `us-east-1` |
| `NEXT_PUBLIC_ENVIRONMENT` | `prod` |

### 5️⃣ **Configurar Aplicación**

1. **App name**: `aws-propuestas-v2`
2. **Environment name**: `main`
3. Habilitar **"Enable full-stack deployments"**: NO (solo frontend)
4. Haz clic en **"Next"**

### 6️⃣ **Revisar y Desplegar**

1. Revisa toda la configuración
2. Haz clic en **"Save and deploy"**
3. Espera a que termine el despliegue (5-10 minutos)

### 7️⃣ **Configurar Dominio Personalizado (Opcional)**

1. Ve a **"Domain management"**
2. Haz clic en **"Add domain"**
3. Ingresa tu dominio personalizado
4. Configura los registros DNS según las instrucciones

## 🎯 **URLs Resultantes**

Después del despliegue tendrás:

- **URL de Amplify**: `https://main.d[random-id].amplifyapp.com`
- **API Backend**: `https://v13oiy941a.execute-api.us-east-1.amazonaws.com/prod`

## 🔧 **Configuración Automática**

Amplify configurará automáticamente:
- ✅ Build de Next.js
- ✅ Deploy automático en cada push a main
- ✅ HTTPS con certificado SSL
- ✅ CDN global con CloudFront
- ✅ Variables de entorno
- ✅ Caché de dependencias

## 🧪 **Verificar Despliegue**

Una vez desplegado:

1. Accede a la URL de Amplify
2. Prueba **Chat Libre** con diferentes modelos
3. Prueba **Arquitecto AWS** para generar propuestas
4. Verifica que la API backend responde correctamente

## 🚨 **Troubleshooting**

### Error de Build
- Verifica que `amplify.yml` esté en la raíz del proyecto
- Revisa los logs de build en la consola de Amplify

### Error de Variables de Entorno
- Verifica que todas las variables estén configuradas
- Asegúrate de que la API URL sea correcta

### Error de CORS
- La API ya tiene CORS configurado
- Si hay problemas, verifica la configuración en API Gateway

## 🎉 **¡Listo!**

Tu AWS Propuestas v2 estará disponible globalmente con:
- 🌐 HTTPS automático
- 🚀 CDN global
- 🔄 Deploy automático
- 📱 Responsive design
- 🤖 90+ modelos de IA disponibles

---

**Tiempo estimado de setup**: 10-15 minutos
**Costo adicional**: ~$1-5/mes (dependiendo del tráfico)
