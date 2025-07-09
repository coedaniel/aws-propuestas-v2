// Tipos base del sistema
export interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  mode: 'chat-libre' | 'arquitecto';
}

export interface ChatSession {
  id: string;
  title: string;
  mode: 'chat-libre' | 'arquitecto';
  messages: Message[];
  createdAt: Date;
  updatedAt: Date;
  userId?: string;
}

// Tipos para el modo Arquitecto AWS
export interface ProyectoArquitecto {
  id: string;
  nombre: string;
  tipo: 'solucion-integral' | 'servicio-rapido';
  estado: 'iniciado' | 'en-progreso' | 'completado';
  datos: DatosProyecto;
  documentos?: DocumentoGenerado[];
  createdAt: Date;
  updatedAt: Date;
}

export interface DatosProyecto {
  // Datos básicos
  nombre: string;
  tipo: string;
  objetivo?: string;
  descripcion?: string;
  
  // Datos técnicos
  serviciosAWS?: string[];
  integraciones?: string[];
  usuarios?: number;
  trafico?: string;
  presupuesto?: string;
  
  // Fechas y restricciones
  fechaInicio?: string;
  fechaEntrega?: string;
  restricciones?: string[];
  
  // Seguridad y compliance
  seguridad?: string[];
  compliance?: string[];
  
  // Alta disponibilidad
  altaDisponibilidad?: boolean;
  multiAZ?: boolean;
  multiRegion?: boolean;
  rto?: string;
  rpo?: string;
  
  // Otros
  comentarios?: string;
}

export interface DocumentoGenerado {
  id: string;
  tipo: 'actividades' | 'cloudformation' | 'diagrama' | 'documento' | 'costos' | 'calculadora';
  nombre: string;
  url: string;
  formato: 'csv' | 'xlsx' | 'yaml' | 'svg' | 'png' | 'drawio' | 'docx';
  createdAt: Date;
}

// Tipos para modelos de Bedrock
export interface BedrockModel {
  id: string;
  name: string;
  provider: 'anthropic' | 'amazon' | 'ai21' | 'cohere' | 'meta' | 'mistral';
  description: string;
  inputTokenPrice: number;
  outputTokenPrice: number;
  maxTokens: number;
  supportsStreaming: boolean;
}

// Tipos para servicios AWS rápidos
export interface ServicioRapido {
  id: string;
  nombre: string;
  descripcion: string;
  categoria: 'compute' | 'storage' | 'database' | 'networking' | 'security' | 'analytics';
  preguntas: PreguntaServicio[];
}

export interface PreguntaServicio {
  id: string;
  pregunta: string;
  tipo: 'text' | 'number' | 'select' | 'multiselect' | 'boolean';
  opciones?: string[];
  requerido: boolean;
  ayuda?: string;
}

// Tipos para respuestas de API
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface BedrockResponse {
  response: string;
  modelId: string;
  usage?: {
    inputTokens: number;
    outputTokens: number;
  };
}

// Tipos para generación de documentos
export interface GenerarDocumentosRequest {
  proyectoId: string;
  bucketS3: string;
  datos: DatosProyecto;
}

export interface GenerarDocumentosResponse {
  documentos: DocumentoGenerado[];
  carpetaS3: string;
  mensaje: string;
}
