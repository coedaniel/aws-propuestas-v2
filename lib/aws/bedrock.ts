import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { BedrockModel, BedrockResponse } from '@/lib/types';

// Cliente de Bedrock
const bedrockClient = new BedrockRuntimeClient({
  region: process.env.AWS_REGION || 'us-east-1',
});

// Modelos disponibles (Amazon + Anthropic)
export const BEDROCK_MODELS: BedrockModel[] = [
  // Anthropic Claude
  {
    id: 'anthropic.claude-3-5-sonnet-20241022-v2:0',
    name: 'Claude 3.5 Sonnet v2',
    provider: 'anthropic',
    description: 'Modelo más avanzado de Anthropic, excelente para tareas complejas',
    inputTokenPrice: 0.003,
    outputTokenPrice: 0.015,
    maxTokens: 8192,
    supportsStreaming: true,
  },
  {
    id: 'anthropic.claude-3-haiku-20240307-v1:0',
    name: 'Claude 3 Haiku',
    provider: 'anthropic',
    description: 'Modelo rápido y eficiente de Anthropic',
    inputTokenPrice: 0.00025,
    outputTokenPrice: 0.00125,
    maxTokens: 4096,
    supportsStreaming: true,
  },
  {
    id: 'anthropic.claude-3-sonnet-20240229-v1:0',
    name: 'Claude 3 Sonnet',
    provider: 'anthropic',
    description: 'Modelo balanceado de Anthropic',
    inputTokenPrice: 0.003,
    outputTokenPrice: 0.015,
    maxTokens: 4096,
    supportsStreaming: true,
  },
  // Amazon Titan
  {
    id: 'amazon.titan-text-premier-v1:0',
    name: 'Titan Text Premier',
    provider: 'amazon',
    description: 'Modelo premier de Amazon para texto',
    inputTokenPrice: 0.0005,
    outputTokenPrice: 0.0015,
    maxTokens: 32000,
    supportsStreaming: false,
  },
  {
    id: 'amazon.titan-text-express-v1',
    name: 'Titan Text Express',
    provider: 'amazon',
    description: 'Modelo express de Amazon para texto',
    inputTokenPrice: 0.0002,
    outputTokenPrice: 0.0006,
    maxTokens: 8000,
    supportsStreaming: false,
  },
  {
    id: 'amazon.titan-text-lite-v1',
    name: 'Titan Text Lite',
    provider: 'amazon',
    description: 'Modelo ligero de Amazon para texto',
    inputTokenPrice: 0.0001,
    outputTokenPrice: 0.0003,
    maxTokens: 4000,
    supportsStreaming: false,
  },
  // Amazon Nova
  {
    id: 'amazon.nova-pro-v1:0',
    name: 'Nova Pro',
    provider: 'amazon',
    description: 'Modelo profesional Nova de Amazon',
    inputTokenPrice: 0.0008,
    outputTokenPrice: 0.0032,
    maxTokens: 60000,
    supportsStreaming: true,
  },
  {
    id: 'amazon.nova-lite-v1:0',
    name: 'Nova Lite',
    provider: 'amazon',
    description: 'Modelo ligero Nova de Amazon',
    inputTokenPrice: 0.00006,
    outputTokenPrice: 0.00024,
    maxTokens: 300000,
    supportsStreaming: true,
  },
  {
    id: 'amazon.nova-micro-v1:0',
    name: 'Nova Micro',
    provider: 'amazon',
    description: 'Modelo micro Nova de Amazon',
    inputTokenPrice: 0.000035,
    outputTokenPrice: 0.00014,
    maxTokens: 128000,
    supportsStreaming: true,
  },
];

// Función para invocar modelo de Bedrock
export async function invokeBedrockModel(
  modelId: string,
  messages: Array<{ role: string; content: string }>,
  systemPrompt?: string
): Promise<BedrockResponse> {
  try {
    const model = BEDROCK_MODELS.find(m => m.id === modelId);
    if (!model) {
      throw new Error(`Modelo no encontrado: ${modelId}`);
    }

    let requestBody: any;

    if (model.provider === 'anthropic') {
      // Formato para modelos Claude
      const claudeMessages = messages.map(msg => ({
        role: msg.role,
        content: msg.content
      }));

      requestBody = {
        anthropic_version: 'bedrock-2023-05-31',
        max_tokens: model.maxTokens,
        messages: claudeMessages,
        temperature: 0.7,
        top_p: 0.9,
      };

      if (systemPrompt) {
        requestBody.system = systemPrompt;
      }
    } else if (model.provider === 'amazon') {
      // Formato para modelos Amazon (Titan/Nova)
      const lastMessage = messages[messages.length - 1];
      
      if (modelId.includes('nova')) {
        // Formato Nova
        requestBody = {
          messages: messages.map(msg => ({
            role: msg.role,
            content: [{ text: msg.content }]
          })),
          inferenceConfig: {
            max_new_tokens: model.maxTokens,
            temperature: 0.7,
            top_p: 0.9,
          }
        };

        if (systemPrompt) {
          requestBody.system = [{ text: systemPrompt }];
        }
      } else {
        // Formato Titan
        requestBody = {
          inputText: lastMessage.content,
          textGenerationConfig: {
            maxTokenCount: model.maxTokens,
            temperature: 0.7,
            topP: 0.9,
          }
        };
      }
    }

    const command = new InvokeModelCommand({
      modelId,
      body: JSON.stringify(requestBody),
      contentType: 'application/json',
    });

    const response = await bedrockClient.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));

    let generatedText: string;
    let usage: any = undefined;

    if (model.provider === 'anthropic') {
      generatedText = responseBody.content[0].text;
      usage = {
        inputTokens: responseBody.usage?.input_tokens || 0,
        outputTokens: responseBody.usage?.output_tokens || 0,
      };
    } else if (model.provider === 'amazon') {
      if (modelId.includes('nova')) {
        generatedText = responseBody.output.message.content[0].text;
        usage = {
          inputTokens: responseBody.usage?.inputTokens || 0,
          outputTokens: responseBody.usage?.outputTokens || 0,
        };
      } else {
        generatedText = responseBody.results[0].outputText;
      }
    } else {
      throw new Error(`Proveedor no soportado: ${model.provider}`);
    }

    return {
      response: generatedText,
      modelId,
      usage,
    };
  } catch (error) {
    console.error('Error invocando modelo Bedrock:', error);
    throw new Error(`Error al invocar modelo: ${error instanceof Error ? error.message : 'Error desconocido'}`);
  }
}

// Función para obtener modelo por ID
export function getModelById(modelId: string): BedrockModel | undefined {
  return BEDROCK_MODELS.find(model => model.id === modelId);
}

// Función para obtener modelos por proveedor
export function getModelsByProvider(provider: string): BedrockModel[] {
  return BEDROCK_MODELS.filter(model => model.provider === provider);
}
