'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { MessageCircle, Settings, Zap, FileText, Cloud, Users } from 'lucide-react';
import { useChatStore } from '@/store/chatStore';
import { useRouter } from 'next/navigation';

export default function HomePage() {
  const { setMode, createNewSession } = useChatStore();
  const router = useRouter();

  const handleModeSelection = (mode: 'chat-libre' | 'arquitecto') => {
    setMode(mode);
    createNewSession(mode);
    router.push(mode === 'chat-libre' ? '/chat' : '/arquitecto');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
      {/* Header */}
      <header className="border-b bg-white/80 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-aws-orange rounded-lg flex items-center justify-center">
                <Cloud className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-slate-900">AWS Propuestas v2</h1>
                <p className="text-sm text-slate-600">Sistema Profesional de Propuestas AWS</p>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Button variant="outline" size="sm">
                <Settings className="w-4 h-4 mr-2" />
                Configuración
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-12">
        <div className="max-w-4xl mx-auto">
          {/* Hero Section */}
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold text-slate-900 mb-4">
              Genera Propuestas AWS Profesionales con IA
            </h2>
            <p className="text-xl text-slate-600 mb-8 max-w-2xl mx-auto">
              Utiliza el poder de Amazon Bedrock para crear propuestas técnicas completas, 
              documentación profesional y arquitecturas AWS optimizadas.
            </p>
          </div>

          {/* Mode Selection Cards */}
          <div className="grid md:grid-cols-2 gap-8 mb-12">
            {/* Chat Libre */}
            <Card className="hover:shadow-lg transition-shadow cursor-pointer group" 
                  onClick={() => handleModeSelection('chat-libre')}>
              <CardHeader>
                <div className="flex items-center space-x-3 mb-2">
                  <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center group-hover:bg-blue-200 transition-colors">
                    <MessageCircle className="w-6 h-6 text-blue-600" />
                  </div>
                  <div>
                    <CardTitle className="text-xl">Chat Libre</CardTitle>
                    <CardDescription>Conversación abierta con IA</CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-slate-600 mb-4">
                  Chatea libremente con modelos de Amazon Bedrock. Perfecto para consultas rápidas, 
                  brainstorming y obtener respuestas técnicas sobre AWS.
                </p>
                <div className="flex flex-wrap gap-2 mb-4">
                  <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded-full">Claude 3.5 Sonnet</span>
                  <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded-full">Nova Pro</span>
                  <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded-full">Titan</span>
                </div>
                <Button className="w-full" variant="outline">
                  Iniciar Chat Libre
                </Button>
              </CardContent>
            </Card>

            {/* Arquitecto AWS */}
            <Card className="hover:shadow-lg transition-shadow cursor-pointer group border-aws-orange/20" 
                  onClick={() => handleModeSelection('arquitecto')}>
              <CardHeader>
                <div className="flex items-center space-x-3 mb-2">
                  <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center group-hover:bg-orange-200 transition-colors">
                    <Zap className="w-6 h-6 text-aws-orange" />
                  </div>
                  <div>
                    <CardTitle className="text-xl text-aws-orange">Arquitecto AWS</CardTitle>
                    <CardDescription>Propuestas profesionales guiadas</CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-slate-600 mb-4">
                  Modo especializado que te guía paso a paso para crear propuestas técnicas completas 
                  con documentación, diagramas y estimaciones de costos.
                </p>
                <div className="flex flex-wrap gap-2 mb-4">
                  <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded-full">Documentos Word</span>
                  <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded-full">CloudFormation</span>
                  <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded-full">Diagramas</span>
                </div>
                <Button className="w-full" variant="aws">
                  Iniciar Arquitecto AWS
                </Button>
              </CardContent>
            </Card>
          </div>

          {/* Features Section */}
          <div className="grid md:grid-cols-3 gap-6 mb-12">
            <div className="text-center">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <FileText className="w-8 h-8 text-green-600" />
              </div>
              <h3 className="text-lg font-semibold mb-2">Documentación Completa</h3>
              <p className="text-slate-600 text-sm">
                Genera documentos Word, Excel, diagramas SVG y scripts CloudFormation automáticamente.
              </p>
            </div>
            <div className="text-center">
              <div className="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Cloud className="w-8 h-8 text-purple-600" />
              </div>
              <h3 className="text-lg font-semibold mb-2">Arquitecturas AWS</h3>
              <p className="text-slate-600 text-sm">
                Diseña soluciones siguiendo las mejores prácticas de AWS Well-Architected Framework.
              </p>
            </div>
            <div className="text-center">
              <div className="w-16 h-16 bg-indigo-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Users className="w-8 h-8 text-indigo-600" />
              </div>
              <h3 className="text-lg font-semibold mb-2">Propuestas Profesionales</h3>
              <p className="text-slate-600 text-sm">
                Crea propuestas ejecutivas listas para presentar a clientes y stakeholders.
              </p>
            </div>
          </div>

          {/* Stats Section */}
          <div className="bg-white rounded-xl p-8 shadow-sm border">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
              <div>
                <div className="text-2xl font-bold text-aws-orange mb-1">8+</div>
                <div className="text-sm text-slate-600">Modelos de IA</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-aws-orange mb-1">50+</div>
                <div className="text-sm text-slate-600">Servicios AWS</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-aws-orange mb-1">6</div>
                <div className="text-sm text-slate-600">Tipos de Documentos</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-aws-orange mb-1">100%</div>
                <div className="text-sm text-slate-600">Automatizado</div>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t bg-white/80 backdrop-blur-sm mt-12">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <p className="text-sm text-slate-600">
              © 2025 AWS Propuestas v2. Construido con Next.js y Amazon Bedrock.
            </p>
            <div className="flex items-center space-x-4">
              <span className="text-xs text-slate-500">Powered by</span>
              <div className="flex items-center space-x-2">
                <div className="w-6 h-6 bg-aws-orange rounded flex items-center justify-center">
                  <Cloud className="w-4 h-4 text-white" />
                </div>
                <span className="text-sm font-medium text-slate-700">Amazon Bedrock</span>
              </div>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
