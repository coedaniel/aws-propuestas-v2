# ✅ Lista de Verificación Post-Despliegue

## Pre-Despliegue

### Prerrequisitos del Sistema
- [ ] AWS CLI instalado y configurado
- [ ] SAM CLI instalado (versión >= 1.70.0)
- [ ] Node.js 18+ instalado
- [ ] npm/yarn disponible
- [ ] Git configurado
- [ ] Permisos de administrador en AWS

### Configuración AWS
- [ ] Credenciales AWS configuradas (`aws configure`)
- [ ] Región configurada (us-east-1 recomendada)
- [ ] Perfil AWS activo
- [ ] Límites de servicio verificados

### Modelos de Bedrock
- [ ] Amazon Nova Pro habilitado (`amazon.nova-pro-v1:0`)
- [ ] Claude 3 Haiku habilitado (`anthropic.claude-3-haiku-20240307-v1:0`)
- [ ] Región Bedrock configurada (us-east-1)

## Durante el Despliegue

### Backend (SAM)
- [ ] `sam build` ejecutado sin errores
- [ ] `sam deploy` completado exitosamente
- [ ] Stack CloudFormation creado
- [ ] Funciones Lambda desplegadas
- [ ] API Gateway configurado
- [ ] DynamoDB tabla creada
- [ ] Roles IAM configurados

### Frontend (Amplify)
- [ ] `npm run build` exitoso
- [ ] Amplify app creada
- [ ] Dominio asignado
- [ ] SSL certificado configurado
- [ ] Variables de entorno configuradas

## Post-Despliegue

### Verificación de Backend

#### Health Check
```bash
curl https://tu-api-id.execute-api.us-east-1.amazonaws.com/prod/health
```
- [ ] Respuesta 200 OK
- [ ] JSON válido retornado
- [ ] Timestamp correcto

#### Endpoint Arquitecto
```bash
curl -X POST https://tu-api-id.execute-api.us-east-1.amazonaws.com/prod/arquitecto \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hola, necesito ayuda con arquitectura"}]}'
```
- [ ] Respuesta 200 OK
- [ ] Respuesta de Nova Pro recibida
- [ ] Tiempo de respuesta < 30s
- [ ] No errores en CloudWatch

#### Endpoint Chat
```bash
curl -X POST https://tu-api-id.execute-api.us-east-1.amazonaws.com/prod/chat \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hola"}]}'
```
- [ ] Respuesta 200 OK
- [ ] Respuesta de Claude Haiku recibida
- [ ] Tiempo de respuesta < 10s
- [ ] No errores en CloudWatch

### Verificación de Frontend

#### Acceso Web
- [ ] URL de Amplify accesible
- [ ] Página carga sin errores
- [ ] CSS/JS cargando correctamente
- [ ] No errores en consola del navegador

#### Funcionalidad
- [ ] Chat básico funciona
- [ ] Modo arquitecto funciona
- [ ] Interfaz responsive
- [ ] Navegación fluida

### Verificación de Integración

#### Frontend ↔ Backend
- [ ] API calls desde frontend exitosas
- [ ] CORS configurado correctamente
- [ ] Variables de entorno correctas
- [ ] Manejo de errores funciona

#### Persistencia
- [ ] Conversaciones se guardan en DynamoDB
- [ ] Historial se recupera correctamente
- [ ] No pérdida de datos

### Monitoreo y Logs

#### CloudWatch Logs
- [ ] Logs de Lambda visibles
- [ ] No errores críticos
- [ ] Métricas de invocación correctas
- [ ] Alertas configuradas (opcional)

#### Métricas
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=aws-propuestas-arquitecto-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```
- [ ] Métricas de Lambda disponibles
- [ ] Sin errores de timeout
- [ ] Cold starts aceptables

### Seguridad

#### IAM
- [ ] Roles con permisos mínimos
- [ ] No credenciales hardcodeadas
- [ ] Políticas específicas por función

#### API Gateway
- [ ] Rate limiting configurado
- [ ] CORS restrictivo
- [ ] Headers de seguridad

#### Bedrock
- [ ] Acceso solo desde Lambda
- [ ] Modelos específicos permitidos
- [ ] Región restringida

### Performance

#### Latencia
- [ ] API Gateway < 100ms overhead
- [ ] Lambda cold start < 2s
- [ ] Lambda warm < 500ms
- [ ] Frontend load < 3s

#### Throughput
- [ ] API soporta carga esperada
- [ ] DynamoDB configurado apropiadamente
- [ ] Sin throttling en Bedrock

### Costos

#### Estimación Inicial
- [ ] Costos dentro del presupuesto
- [ ] Billing alerts configuradas
- [ ] Uso de free tier optimizado

#### Monitoreo
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 day ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```
- [ ] Costos por servicio visibles
- [ ] Sin gastos inesperados

## Troubleshooting

### Problemas Comunes

#### Error 500 en API
- [ ] Verificar logs de Lambda
- [ ] Confirmar modelos Bedrock habilitados
- [ ] Revisar permisos IAM

#### CORS Error
- [ ] Ejecutar `./scripts/fix-cors.sh`
- [ ] Verificar configuración API Gateway
- [ ] Confirmar dominios permitidos

#### Frontend no carga
- [ ] Verificar build de Amplify
- [ ] Confirmar variables de entorno
- [ ] Revisar configuración DNS

#### Timeout en Lambda
- [ ] Aumentar timeout en template.yaml
- [ ] Optimizar código Python
- [ ] Verificar conectividad Bedrock

### Comandos de Diagnóstico

#### Ver logs en tiempo real
```bash
aws logs tail /aws/lambda/aws-propuestas-arquitecto-prod --follow
```

#### Verificar stack
```bash
aws cloudformation describe-stacks --stack-name aws-propuestas-v2-prod
```

#### Test local
```bash
cd infrastructure
sam local start-api
```

## Rollback Plan

### En caso de problemas críticos

#### Backend
```bash
aws cloudformation delete-stack --stack-name aws-propuestas-v2-prod
```

#### Frontend
```bash
amplify delete
```

#### Restaurar versión anterior
```bash
git checkout <previous-commit>
./scripts/deploy.sh
```

## Sign-off

### Responsables
- [ ] **Desarrollador**: Verificación técnica completa
- [ ] **DevOps**: Infraestructura y monitoreo
- [ ] **QA**: Testing funcional
- [ ] **Product Owner**: Aceptación de funcionalidades

### Documentación
- [ ] README actualizado
- [ ] Documentación API actualizada
- [ ] Runbooks creados
- [ ] Contactos de soporte definidos

### Fecha de Despliegue: _______________
### Versión Desplegada: _______________
### Aprobado por: _______________

---

## 🎉 ¡Despliegue Completado!

Una vez completada esta lista, tu aplicación AWS Propuestas v2 estará completamente operativa y lista para producción.

**Próximos pasos recomendados:**
1. Configurar monitoreo avanzado
2. Implementar backup automático
3. Planificar actualizaciones regulares
4. Documentar procedimientos operativos
