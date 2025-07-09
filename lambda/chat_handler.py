import json
import boto3
import logging
import os
from datetime import datetime
from typing import Dict, Any, List
import uuid

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

# DynamoDB table
table_name = os.environ.get('DYNAMODB_TABLE')
table = dynamodb.Table(table_name) if table_name else None

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for chat functionality
    """
    try:
        # Handle CORS preflight requests
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                'body': ''
            }

        # Parse the request body
        if 'body' in event and event['body']:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            return create_error_response(400, 'No request body provided')

        messages = body.get('messages', [])
        model_id = body.get('modelId', 'anthropic.claude-3-haiku-20240307-v1:0')
        mode = body.get('mode', 'chat-libre')
        session_id = body.get('sessionId')

        if not messages:
            return create_error_response(400, 'No messages provided')

        # Process based on mode
        if mode == 'chat-libre':
            response_text = process_chat_libre(messages, model_id)
        elif mode == 'arquitecto':
            response_text = process_arquitecto_mode(messages, model_id, session_id)
        else:
            return create_error_response(400, f'Invalid mode: {mode}')

        # Save session to DynamoDB if table is available
        if table and session_id:
            save_chat_session(session_id, messages, response_text, mode)

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            'body': json.dumps({
                'response': response_text,
                'modelId': model_id,
                'mode': mode
            })
        }

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_error_response(500, f'Internal server error: {str(e)}')

def process_chat_libre(messages: List[Dict], model_id: str) -> str:
    """
    Process free chat mode
    """
    return invoke_bedrock_model(model_id, messages)

def process_arquitecto_mode(messages: List[Dict], model_id: str, session_id: str) -> str:
    """
    Process architect mode with master prompt
    """
    # Master prompt for AWS Architect mode
    system_prompt = """Actua como arquitecto de soluciones AWS y consultor experto. Vamos a dimensionar, documentar y entregar una solucion profesional en AWS, siguiendo mejores practicas y generando todos los archivos necesarios para una propuesta ejecutiva. No uses acentos ni caracteres especiales en ningun texto, archivo, script ni documento. Asegura que todos los archivos Word generados sean funcionales y compatibles: entrega solo texto plano, sin imagenes, sin tablas complejas, ni formato avanzado, solo texto estructurado, claro y legible. Solo genera scripts CloudFormation como entregable de automatizacion, no generes ningun otro tipo de script.

Primero pregunta:  
Cual es el nombre del proyecto

Despues pregunta:  
El proyecto es una solucion integral (como migracion, aplicacion nueva, modernizacion, analitica, seguridad, IA, IoT, data lake, networking, DRP, VDI, integracion, etc.)  
o es un servicio rapido especifico (implementacion de instancias EC2, RDS, SES, VPN, ELB, S3, VPC, CloudFront, SSO, backup, etc.)

Si elige "servicio rapido especifico":
1. Muestra un catalogo de servicios rapidos comunes y permite elegir uno o varios, o escribir el requerimiento.
2. Haz solo las preguntas minimas necesarias para cada servicio elegido, de forma clara y una por una.
3. Con la informacion, genera y entrega SIEMPRE:
- Tabla de actividades de implementacion (CSV o Excel, clara y lista para importar o compartir, SIN acentos ni caracteres especiales).
- Script CloudFormation para desplegar el servicio (SIN acentos ni caracteres especiales en recursos ni nombres).
- Diagrama de arquitectura en SVG, PNG y Draw.io editable (nombres y etiquetas SIN acentos ni caracteres especiales).
- Documento Word con el objetivo y la descripcion real del proyecto (texto plano, sin acentos, sin imagenes, sin tablas complejas, sin formato avanzado, solo texto claro y estructurado).
- Archivo de costos estimados (CSV o Excel, solo de servicios AWS, sin incluir data transfer, SIN acentos).
- Guia paso a paso de que parametros ingresar en la calculadora oficial de AWS (servicios, recomendaciones, supuestos, sin acentos).
4. Antes de finalizar, pregunta en que bucket S3 deseas subir la carpeta con todos los documentos generados.
5. Sube todos los archivos en una carpeta con el nombre del proyecto y confirma que la carga fue exitosa (no muestres links de descarga).
6. Pregunta si deseas agregar algun comentario o ajuste final antes de terminar.

Si elige "solucion integral" (proyecto complejo):
1. Haz una entrevista guiada, una pregunta a la vez, para capturar:
- Nombre del proyecto (si no lo has hecho ya)
- Tipo de solucion (puede ser varias: migracion, app nueva, modernizacion, etc.)
- Objetivo principal
- Descripcion detallada del proyecto
- Caracteristicas clave requeridas
- Componentes o servicios AWS deseados
- Cantidad y tipo de recursos principales
- Integraciones necesarias (on-premises, SaaS, APIs, IoT, etc.)
- Requisitos de seguridad y compliance
- Alta disponibilidad, DRP, continuidad (multi-AZ, multi-region, RTO, RPO, backups)
- Estimacion de usuarios, trafico, cargas
- Presupuesto disponible (opcional)
- Fechas de inicio y entrega deseadas
- Restricciones tecnicas, negocio o preferencias tecnologicas
- Comentarios o necesidades adicionales (opcional)

2. Aplica logica condicional segun tipo de solucion para profundizar en temas especificos (por ejemplo: migracion, analitica, IoT, seguridad, networking, DRP).

3. Con la informacion capturada, genera y entrega SIEMPRE:
- Tabla de actividades de implementacion (CSV o Excel, profesional y clara, SIN acentos ni caracteres especiales).
- Script CloudFormation para desplegar la solucion completa (SIN acentos ni caracteres especiales en recursos ni nombres).
- Dos diagramas de arquitectura (SVG, PNG, Draw.io editable, layout profesional, SIN acentos).
- Documento Word con objetivo, descripcion, actividades, diagramas y costos (solo texto plano, sin acentos, sin imagenes, sin tablas complejas, sin formato avanzado).
- Costos estimados (CSV o Excel, solo servicios AWS, sin data transfer, sin acentos).
- Guia paso a paso para la calculadora oficial de AWS (sin acentos).

4. Pregunta en que bucket S3 deseas subir la carpeta con todos los documentos.
5. Sube todos los archivos generados a una carpeta con el nombre del proyecto y confirma la carga exitosa (sin mostrar links de descarga).
6. Permite agregar comentarios o ajustes antes de cerrar la propuesta.

En todas las preguntas y entregas:
- Se claro, especifico y pregunta una cosa a la vez.
- Si alguna respuesta es vaga o insuficiente, pide mas detalle o ejemplos antes de avanzar.
- Todos los archivos deben conservar formato profesional y ser compatibles para edicion o firma.
- El flujo es siempre guiado y conversacional.
- No uses acentos ni caracteres especiales en ningun momento, en ningun archivo ni campo.

El modelo debe ser suficientemente inteligente para adaptar este flujo maestro a lo que el usuario escriba.
Si el usuario da respuestas en otro orden, usa frases libres o menciona algo fuera del guion, el sistema debe:
- Entender la intencion.
- Detectar que informacion ya se tiene y cual falta.
- Hacer nuevas preguntas segun lo que el usuario diga.
- No repetir preguntas innecesarias.
- Completar los entregables con la informacion disponible.

La conversacion debe sentirse natural, como con un arquitecto de soluciones AWS real. El flujo puede reordenarse o adaptarse dinamicamente, y el modelo debe continuar preguntando lo necesario para llegar a un resultado profesional."""

    return invoke_bedrock_model(model_id, messages, system_prompt)

def invoke_bedrock_model(model_id: str, messages: List[Dict], system_prompt: str = None) -> str:
    """
    Invoke Bedrock model with conversation history
    """
    try:
        # Convert messages to Bedrock format and ensure alternating roles
        bedrock_messages = []
        last_role = None
        
        for msg in messages:
            current_role = msg['role']
            
            # Skip consecutive messages with the same role (except the first one)
            if last_role == current_role:
                # If we have consecutive user messages, combine them
                if current_role == 'user' and bedrock_messages:
                    bedrock_messages[-1]['content'] += f"\n\n{msg['content']}"
                    continue
                # If we have consecutive assistant messages, skip the previous one
                elif current_role == 'assistant' and bedrock_messages:
                    bedrock_messages[-1] = {
                        "role": current_role,
                        "content": msg['content']
                    }
                    continue
            
            bedrock_messages.append({
                "role": current_role,
                "content": msg['content']
            })
            last_role = current_role

        # Prepare request based on model provider
        if model_id.startswith('anthropic.claude'):
            # Claude format - send full conversation history
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 4096,
                "messages": bedrock_messages,
                "temperature": 0.7,
                "top_p": 0.9,
            }
            
            if system_prompt:
                request_body["system"] = system_prompt
                
        elif model_id.startswith('amazon.nova'):
            # Nova format
            request_body = {
                "messages": [{"role": msg["role"], "content": [{"text": msg["content"]}]} for msg in bedrock_messages],
                "inferenceConfig": {
                    "max_new_tokens": 4096,
                    "temperature": 0.7,
                    "top_p": 0.9,
                }
            }
            
            if system_prompt:
                request_body["system"] = [{"text": system_prompt}]
                
        elif model_id.startswith('amazon.titan'):
            # Titan format - use last message only (Titan doesn't support conversation history)
            user_message = messages[-1]['content'] if messages else ""
            request_body = {
                "inputText": user_message,
                "textGenerationConfig": {
                    "maxTokenCount": 4096,
                    "temperature": 0.7,
                    "topP": 0.9,
                }
            }
        else:
            raise ValueError(f"Unsupported model: {model_id}")

        # Call Bedrock
        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps(request_body),
            contentType='application/json'
        )

        # Parse response
        response_body = json.loads(response['body'].read())

        # Extract generated text based on model type
        if model_id.startswith('anthropic.claude'):
            generated_text = response_body['content'][0]['text']
        elif model_id.startswith('amazon.nova'):
            generated_text = response_body['output']['message']['content'][0]['text']
        elif model_id.startswith('amazon.titan'):
            generated_text = response_body['results'][0]['outputText']
        else:
            generated_text = 'Error: Unsupported model response format'

        return generated_text

    except Exception as e:
        logger.error(f"Error invoking Bedrock model: {str(e)}")
        raise Exception(f"Error invoking model: {str(e)}")

def save_chat_session(session_id: str, messages: List[Dict], response: str, mode: str):
    """
    Save chat session to DynamoDB
    """
    try:
        if not table:
            return
            
        # Add assistant response to messages
        all_messages = messages + [{
            'id': str(uuid.uuid4()),
            'role': 'assistant',
            'content': response,
            'timestamp': datetime.utcnow().isoformat()
        }]
        
        table.put_item(
            Item={
                'id': session_id,
                'messages': all_messages,
                'mode': mode,
                'updatedAt': datetime.utcnow().isoformat(),
                'createdAt': datetime.utcnow().isoformat()
            }
        )
        
    except Exception as e:
        logger.error(f"Error saving chat session: {str(e)}")
        # Don't fail the request if we can't save to DynamoDB

def create_error_response(status_code: int, message: str) -> Dict[str, Any]:
    """
    Create standardized error response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps({
            'error': message
        })
    }
