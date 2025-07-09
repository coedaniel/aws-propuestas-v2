import json
import boto3
import os
from typing import Dict, List, Any
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('REGION', 'us-east-1'))
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('REGION', 'us-east-1'))
s3 = boto3.client('s3', region_name=os.environ.get('REGION', 'us-east-1'))

# Get table and bucket names from environment
PROJECTS_TABLE = os.environ.get('PROJECTS_TABLE')
DOCUMENTS_BUCKET = os.environ.get('DOCUMENTS_BUCKET')

projects_table = dynamodb.Table(PROJECTS_TABLE) if PROJECTS_TABLE else None

def lambda_handler(event, context):
    """
    AWS Lambda handler for arquitecto functionality
    """
    try:
        # Parse the request
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        # Extract parameters
        action = body.get('action', 'chat')
        project_data = body.get('projectData', {})
        session_id = body.get('sessionId')
        
        if action == 'generate_documents':
            return generate_project_documents(project_data, session_id, context)
        elif action == 'save_project':
            return save_project_data(project_data, session_id, context)
        else:
            # Default chat functionality
            messages = body.get('messages', [])
            model_id = body.get('modelId', 'amazon.nova-pro-v1:0')
            
            return process_arquitecto_chat(messages, model_id, session_id, context)
        
    except Exception as e:
        logger.error(f"Error in arquitecto handler: {str(e)}")
        return create_response(500, {
            'error': 'Internal server error',
            'details': str(e)
        })

def process_arquitecto_chat(messages: List[Dict], model_id: str, session_id: str, context) -> Dict:
    """Process chat with arquitecto mode"""
    
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

Si elige "solucion integral" (proyecto complejo):
1. Haz una entrevista guiada, una pregunta a la vez, para capturar todos los requerimientos
2. Con la informacion capturada, genera y entrega SIEMPRE la documentacion completa

En todas las preguntas y entregas:
- Se claro, especifico y pregunta una cosa a la vez.
- Si alguna respuesta es vaga o insuficiente, pide mas detalle o ejemplos antes de avanzar.
- Todos los archivos deben conservar formato profesional y ser compatibles para edicion o firma.
- El flujo es siempre guiado y conversacional.
- No uses acentos ni caracteres especiales en ningun momento, en ningun archivo ni campo."""

    # Prepare prompt for Bedrock
    if model_id.startswith('anthropic.claude'):
        prompt_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4000,
            "system": system_prompt,
            "messages": messages
        }
    elif model_id.startswith('amazon.nova'):
        # Nova requires content to be an array and system message to be included as first user message
        nova_messages = [{
            "role": "user", 
            "content": [{"text": system_prompt + "\n\nUsuario: " + messages[0].get('content', '')}]
        }]
        if len(messages) > 1:
            for msg in messages[1:]:
                nova_messages.append({
                    "role": msg.get('role', 'user'),
                    "content": [{"text": msg.get('content', '')}]
                })
        
        prompt_body = {
            "messages": nova_messages,
            "inferenceConfig": {
                "max_new_tokens": 4000,
                "temperature": 0.7
            }
        }
    else:
        prompt_body = {
            "messages": [{"role": "system", "content": system_prompt}] + messages,
            "max_tokens": 4000,
            "temperature": 0.7
        }
    
    # Call Bedrock
    logger.info(f"🏗️ ARQUITECTO USING MODEL: {model_id}")
    logger.info(f"📝 PROMPT BODY: {json.dumps(prompt_body, indent=2)}")
    
    response = bedrock_runtime.invoke_model(
        modelId=model_id,
        body=json.dumps(prompt_body),
        contentType='application/json'
    )
    
    # Parse response
    response_body = json.loads(response['body'].read())
    
    if model_id.startswith('anthropic.claude'):
        ai_response = response_body.get('content', [{}])[0].get('text', '')
    elif model_id.startswith('amazon.nova'):
        ai_response = response_body.get('output', {}).get('message', {}).get('content', [{}])[0].get('text', '')
    else:
        ai_response = response_body.get('content', '')
    
    return create_response(200, {
        'response': ai_response,
        'modelId': model_id,
        'mode': 'arquitecto',
        'usage': response_body.get('usage', {})
    })

def generate_project_documents(project_data: Dict, session_id: str, context) -> Dict:
    """Generate project documents and upload to S3"""
    try:
        # This would contain the logic to generate documents
        # For now, return a placeholder response
        documents = {
            'propuesta_ejecutiva.docx': 'Generated Word document content',
            'cloudformation_template.yaml': 'Generated CloudFormation template',
            'diagrama_arquitectura.svg': 'Generated architecture diagram',
            'estimacion_costos.csv': 'Generated cost estimation',
            'plan_implementacion.csv': 'Generated implementation plan'
        }
        
        # Upload documents to S3 (placeholder)
        s3_urls = {}
        for doc_name, content in documents.items():
            # In real implementation, generate actual documents
            s3_key = f"projects/{session_id}/{doc_name}"
            s3_urls[doc_name] = f"s3://{DOCUMENTS_BUCKET}/{s3_key}"
        
        return create_response(200, {
            'message': 'Documents generated successfully',
            'documents': s3_urls,
            'project_data': project_data
        })
        
    except Exception as e:
        logger.error(f"Error generating documents: {str(e)}")
        return create_response(500, {'error': str(e)})

def save_project_data(project_data: Dict, session_id: str, context) -> Dict:
    """Save project data to DynamoDB"""
    try:
        if projects_table:
            projects_table.put_item(
                Item={
                    'sessionId': session_id,
                    'projectData': project_data,
                    'timestamp': context.aws_request_id,
                    'status': 'active'
                }
            )
        
        return create_response(200, {
            'message': 'Project data saved successfully',
            'sessionId': session_id
        })
        
    except Exception as e:
        logger.error(f"Error saving project: {str(e)}")
        return create_response(500, {'error': str(e)})

def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Create HTTP response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
        'body': json.dumps(body, ensure_ascii=False)
    }
