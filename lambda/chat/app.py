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

# Get table names from environment
CHAT_SESSIONS_TABLE = os.environ.get('CHAT_SESSIONS_TABLE')
chat_table = dynamodb.Table(CHAT_SESSIONS_TABLE) if CHAT_SESSIONS_TABLE else None

def lambda_handler(event, context):
    """
    AWS Lambda handler for chat functionality
    """
    try:
        # Parse the request
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        # Extract parameters
        messages = body.get('messages', [])
        model_id = body.get('modelId', 'anthropic.claude-3-haiku-20240307-v1:0')
        mode = body.get('mode', 'chat-libre')
        session_id = body.get('sessionId')
        
        # Validate input
        if not messages:
            return create_response(400, {'error': 'Messages are required'})
        
        # Prepare the prompt for Bedrock
        if model_id.startswith('anthropic.claude'):
            # Claude format
            system_prompt = get_system_prompt(mode)
            prompt_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 4000,
                "system": system_prompt,
                "messages": messages
            }
        elif model_id.startswith('amazon.nova'):
            # Nova format
            system_prompt = get_system_prompt(mode)
            prompt_body = {
                "messages": [{"role": "system", "content": system_prompt}] + messages,
                "max_tokens": 4000,
                "temperature": 0.7
            }
        else:
            # Default format
            system_prompt = get_system_prompt(mode)
            prompt_body = {
                "messages": [{"role": "system", "content": system_prompt}] + messages,
                "max_tokens": 4000,
                "temperature": 0.7
            }
        
        # Call Bedrock
        logger.info(f"Calling Bedrock model: {model_id}")
        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps(prompt_body),
            contentType='application/json'
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        
        # Extract content based on model
        if model_id.startswith('anthropic.claude'):
            ai_response = response_body.get('content', [{}])[0].get('text', '')
        elif model_id.startswith('amazon.nova'):
            ai_response = response_body.get('output', {}).get('message', {}).get('content', [{}])[0].get('text', '')
        else:
            ai_response = response_body.get('content', '')
        
        # Save to DynamoDB if session_id provided
        if session_id and chat_table:
            try:
                chat_table.put_item(
                    Item={
                        'sessionId': session_id,
                        'timestamp': context.aws_request_id,
                        'messages': messages,
                        'response': ai_response,
                        'modelId': model_id,
                        'mode': mode
                    }
                )
            except Exception as e:
                logger.warning(f"Failed to save to DynamoDB: {str(e)}")
        
        # Return response
        return create_response(200, {
            'response': ai_response,
            'modelId': model_id,
            'mode': mode,
            'usage': response_body.get('usage', {})
        })
        
    except Exception as e:
        logger.error(f"Error in chat handler: {str(e)}")
        return create_response(500, {
            'error': 'Internal server error',
            'details': str(e)
        })

def get_system_prompt(mode: str) -> str:
    """Get system prompt based on mode"""
    if mode == 'arquitecto':
        return """Actua como arquitecto de soluciones AWS y consultor experto. Vamos a dimensionar, documentar y entregar una solucion profesional en AWS, siguiendo mejores practicas y generando todos los archivos necesarios para una propuesta ejecutiva. No uses acentos ni caracteres especiales en ningun texto, archivo, script ni documento.

Primero pregunta: Cual es el nombre del proyecto

Despues pregunta: El proyecto es una solucion integral o es un servicio rapido especifico

Si elige "servicio rapido especifico":
1. Muestra un catalogo de servicios rapidos comunes
2. Haz solo las preguntas minimas necesarias
3. Genera documentacion completa

Si elige "solucion integral":
1. Haz una entrevista guiada completa
2. Captura todos los requerimientos
3. Genera propuesta ejecutiva completa

Siempre genera:
- Documento Word con propuesta
- Script CloudFormation
- Diagramas de arquitectura
- Estimacion de costos
- Plan de implementacion"""
    else:
        return """Eres un asistente experto en AWS que ayuda con consultas tecnicas, arquitecturas, mejores practicas y soluciones en la nube. Proporciona respuestas claras, precisas y profesionales sobre servicios AWS, implementaciones y recomendaciones."""

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
