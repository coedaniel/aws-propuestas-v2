'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ArrowLeft, Send, Bot, User, FileText, Download } from 'lucide-react';
import { useRouter } from 'next/navigation';
import ModelSelector from '@/components/ModelSelector';

interface Message {
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface ProjectInfo {
  name: string;
  description: string;
  requirements: string[];
  budget: string;
  timeline: string;
}

const GUIDED_QUESTIONS = [
  "¿Cuál es el nombre y objetivo principal de tu proyecto?",
  "¿Qué tipo de aplicación o sistema necesitas desarrollar?",
  "¿Cuáles son los requisitos técnicos específicos?",
  "¿Cuál es tu presupuesto estimado y cronograma?",
  "¿Tienes alguna preferencia de servicios AWS específicos?"
];

export default function ArquitectoPage() {
  const router = useRouter();
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [selectedModel, setSelectedModel] = useState('anthropic.claude-3-haiku-20240307-v1:0'); // Default Claude Haiku
  const [isLoading, setIsLoading] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const [projectInfo, setProjectInfo] = useState<Partial<ProjectInfo>>({});
  const [showProposal, setShowProposal] = useState(false);

  const sendMessage = async (messageContent?: string) => {
    const content = messageContent || input;
    if (!content.trim() || isLoading) return;

    const userMessage: Message = {
      role: 'user',
      content,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/Prod';
      const response = await fetch(`${API_BASE_URL}/arquitecto`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messages: [...messages, userMessage].map(m => ({ role: m.role, content: m.content })),
          currentStep,
          projectInfo,
          model: selectedModel
        }),
      });

      if (!response.ok) {
        throw new Error('Error en la respuesta');
      }

      const data = await response.json();
      
      const assistantMessage: Message = {
        role: 'assistant',
        content: data.response,
        timestamp: new Date()
      };

      setMessages(prev => [...prev, assistantMessage]);
      
      // Update project info and step
      if (data.projectInfo) {
        setProjectInfo(data.projectInfo);
      }
      if (data.nextStep !== undefined) {
        setCurrentStep(data.nextStep);
      }
      if (data.showProposal) {
        setShowProposal(true);
      }
    } catch (error) {
      console.error('Error:', error);
      const errorMessage: Message = {
        role: 'assistant',
        content: 'Lo siento, hubo un error al procesar tu mensaje. Por favor, intenta nuevamente.',
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const startGuidedProcess = () => {
    const welcomeMessage: Message = {
      role: 'assistant',
      content: `¡Perfecto! Te ayudaré a crear una propuesta AWS profesional paso a paso.\n\n${GUIDED_QUESTIONS[0]}`,
      timestamp: new Date()
    };
    setMessages([welcomeMessage]);
    setCurrentStep(1);
  };

  const generateProposal = async () => {
    setIsLoading(true);
    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/Prod';
      const response = await fetch(`${API_BASE_URL}/documents`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          projectInfo,
          messages: messages.map(m => ({ role: m.role, content: m.content })),
          model: selectedModel
        }),
      });

      if (!response.ok) {
        throw new Error('Error generando propuesta');
      }

      const data = await response.json();
      
      // Download the proposal
      const link = document.createElement('a');
      link.href = data.downloadUrl;
      link.download = `propuesta-${projectInfo.name || 'proyecto'}.pdf`;
      link.click();
      
    } catch (error) {
      console.error('Error:', error);
      alert('Error al generar la propuesta. Por favor, intenta nuevamente.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="border-b bg-white/80 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <Button
                variant="outline"
                size="sm"
                onClick={() => router.push('/')}
              >
                <ArrowLeft className="w-4 h-4 mr-2" />
                Volver
              </Button>
              <div>
                <h1 className="text-2xl font-bold text-slate-900">Arquitecto AWS</h1>
                <p className="text-sm text-slate-600">Generador de propuestas profesionales</p>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <ModelSelector
                selectedModel={selectedModel}
                onModelChange={setSelectedModel}
                disabled={isLoading}
                compact={true}
              />
              {showProposal && (
                <Button onClick={generateProposal} disabled={isLoading}>
                  <Download className="w-4 h-4 mr-2" />
                  Generar Propuesta
                </Button>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-6 max-w-4xl">
        {messages.length === 0 ? (
          /* Welcome Screen */
          <div className="text-center py-20">
            <div className="bg-white rounded-xl shadow-sm border p-8 max-w-2xl mx-auto">
              <Bot className="w-16 h-16 mx-auto mb-6 text-blue-600" />
              <h2 className="text-2xl font-bold text-slate-900 mb-4">
                ¡Bienvenido al Arquitecto AWS!
              </h2>
              <p className="text-gray-600 mb-8">
                Te guiaré paso a paso para crear una propuesta AWS profesional y detallada 
                para tu proyecto. Analizaremos tus necesidades y generaremos una arquitectura 
                optimizada con estimaciones de costos.
              </p>
              
              <div className="grid md:grid-cols-2 gap-4 mb-8">
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg">Proceso Guiado</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-gray-600">
                      Te haré preguntas específicas para entender tu proyecto y crear 
                      una propuesta personalizada.
                    </p>
                  </CardContent>
                </Card>
                
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg">Propuesta Profesional</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-gray-600">
                      Generaremos un documento PDF completo con arquitectura, 
                      servicios y estimaciones de costos.
                    </p>
                  </CardContent>
                </Card>
              </div>
              
              <Button onClick={startGuidedProcess} size="lg" className="w-full md:w-auto">
                <FileText className="w-5 h-5 mr-2" />
                Comenzar Proceso Guiado
              </Button>
            </div>
          </div>
        ) : (
          /* Chat Interface */
          <div className="bg-white rounded-xl shadow-sm border h-[calc(100vh-200px)] flex flex-col">
            {/* Progress Indicator */}
            {currentStep > 0 && currentStep <= GUIDED_QUESTIONS.length && (
              <div className="border-b p-4">
                <div className="flex items-center justify-between text-sm text-gray-600">
                  <span>Paso {currentStep} de {GUIDED_QUESTIONS.length}</span>
                  <div className="flex space-x-1">
                    {Array.from({ length: GUIDED_QUESTIONS.length }, (_, i) => (
                      <div
                        key={i}
                        className={`w-2 h-2 rounded-full ${
                          i < currentStep ? 'bg-blue-600' : 'bg-gray-300'
                        }`}
                      />
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-6 space-y-4">
              {messages.map((message, index) => (
                <div
                  key={index}
                  className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  <div
                    className={`max-w-[80%] rounded-lg px-4 py-2 ${
                      message.role === 'user'
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 text-gray-900'
                    }`}
                  >
                    <div className="flex items-start space-x-2">
                      {message.role === 'assistant' && (
                        <Bot className="w-5 h-5 mt-0.5 flex-shrink-0" />
                      )}
                      {message.role === 'user' && (
                        <User className="w-5 h-5 mt-0.5 flex-shrink-0" />
                      )}
                      <div className="flex-1">
                        <p className="whitespace-pre-wrap">{message.content}</p>
                        <p className={`text-xs mt-1 ${
                          message.role === 'user' ? 'text-blue-200' : 'text-gray-500'
                        }`}>
                          {message.timestamp.toLocaleTimeString()}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
              {isLoading && (
                <div className="flex justify-start">
                  <div className="bg-gray-100 rounded-lg px-4 py-2">
                    <div className="flex items-center space-x-2">
                      <Bot className="w-5 h-5" />
                      <div className="flex space-x-1">
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Input */}
            <div className="border-t p-4">
              <div className="flex space-x-2">
                <textarea
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyPress={handleKeyPress}
                  placeholder="Escribe tu respuesta aquí..."
                  className="flex-1 resize-none border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  rows={2}
                  disabled={isLoading}
                />
                <Button
                  onClick={() => sendMessage()}
                  disabled={!input.trim() || isLoading}
                  className="px-4 py-2"
                >
                  <Send className="w-4 h-4" />
                </Button>
              </div>
              {currentStep > 0 && currentStep <= GUIDED_QUESTIONS.length && (
                <p className="text-xs text-gray-500 mt-2">
                  Pregunta actual: {GUIDED_QUESTIONS[currentStep - 1]}
                </p>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
