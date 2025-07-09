import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { v4 as uuid } from 'uuid';
import { Message, ChatSession, BedrockModel } from '@/lib/types';
import { BEDROCK_MODELS } from '@/lib/aws/bedrock';

interface ChatStore {
  // Estado actual
  currentSession: ChatSession | null;
  sessions: ChatSession[];
  selectedModel: BedrockModel;
  isLoading: boolean;
  mode: 'chat-libre' | 'arquitecto';
  
  // Acciones
  setMode: (mode: 'chat-libre' | 'arquitecto') => void;
  setSelectedModel: (model: BedrockModel) => void;
  createNewSession: (mode: 'chat-libre' | 'arquitecto') => void;
  loadSession: (sessionId: string) => void;
  sendMessage: (content: string) => Promise<void>;
  clearCurrentSession: () => void;
  deleteSession: (sessionId: string) => void;
  updateSessionTitle: (sessionId: string, title: string) => void;
}

export const useChatStore = create<ChatStore>()(
  persist(
    (set, get) => ({
      // Estado inicial
      currentSession: null,
      sessions: [],
      selectedModel: BEDROCK_MODELS[0], // Claude 3.5 Sonnet por defecto
      isLoading: false,
      mode: 'chat-libre',

      // Cambiar modo
      setMode: (mode) => {
        set({ mode });
        // Si cambiamos de modo, crear nueva sesión
        get().createNewSession(mode);
      },

      // Cambiar modelo
      setSelectedModel: (model) => {
        set({ selectedModel: model });
      },

      // Crear nueva sesión
      createNewSession: (mode) => {
        const newSession: ChatSession = {
          id: uuid(),
          title: mode === 'chat-libre' ? 'Chat Libre' : 'Arquitecto AWS',
          mode,
          messages: [],
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        set((state) => ({
          currentSession: newSession,
          sessions: [newSession, ...state.sessions],
        }));
      },

      // Cargar sesión existente
      loadSession: (sessionId) => {
        const session = get().sessions.find(s => s.id === sessionId);
        if (session) {
          set({ 
            currentSession: session,
            mode: session.mode 
          });
        }
      },

      // Enviar mensaje
      sendMessage: async (content) => {
        const { currentSession, selectedModel, mode } = get();
        
        if (!currentSession) {
          get().createNewSession(mode);
          return get().sendMessage(content);
        }

        // Crear mensaje del usuario
        const userMessage: Message = {
          id: uuid(),
          role: 'user',
          content,
          timestamp: new Date(),
          mode,
        };

        // Actualizar sesión con mensaje del usuario
        const updatedSession = {
          ...currentSession,
          messages: [...currentSession.messages, userMessage],
          updatedAt: new Date(),
        };

        set((state) => ({
          currentSession: updatedSession,
          sessions: state.sessions.map(s => 
            s.id === updatedSession.id ? updatedSession : s
          ),
          isLoading: true,
        }));

        try {
          // Llamar a la API
          const response = await fetch('/api/chat', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              messages: updatedSession.messages.map(m => ({
                role: m.role,
                content: m.content,
              })),
              modelId: selectedModel.id,
              mode,
              sessionId: updatedSession.id,
            }),
          });

          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }

          const data = await response.json();

          // Crear mensaje del asistente
          const assistantMessage: Message = {
            id: uuid(),
            role: 'assistant',
            content: data.response,
            timestamp: new Date(),
            mode,
          };

          // Actualizar sesión con respuesta
          const finalSession = {
            ...updatedSession,
            messages: [...updatedSession.messages, assistantMessage],
            updatedAt: new Date(),
          };

          // Actualizar título si es el primer mensaje
          if (finalSession.messages.length === 2) {
            const title = content.length > 50 
              ? content.substring(0, 50) + '...' 
              : content;
            finalSession.title = title;
          }

          set((state) => ({
            currentSession: finalSession,
            sessions: state.sessions.map(s => 
              s.id === finalSession.id ? finalSession : s
            ),
            isLoading: false,
          }));

        } catch (error) {
          console.error('Error enviando mensaje:', error);
          
          // Crear mensaje de error
          const errorMessage: Message = {
            id: uuid(),
            role: 'assistant',
            content: 'Lo siento, ocurrió un error al procesar tu mensaje. Por favor, intenta de nuevo.',
            timestamp: new Date(),
            mode,
          };

          const errorSession = {
            ...updatedSession,
            messages: [...updatedSession.messages, errorMessage],
            updatedAt: new Date(),
          };

          set((state) => ({
            currentSession: errorSession,
            sessions: state.sessions.map(s => 
              s.id === errorSession.id ? errorSession : s
            ),
            isLoading: false,
          }));
        }
      },

      // Limpiar sesión actual
      clearCurrentSession: () => {
        const { currentSession } = get();
        if (currentSession) {
          const clearedSession = {
            ...currentSession,
            messages: [],
            updatedAt: new Date(),
          };

          set((state) => ({
            currentSession: clearedSession,
            sessions: state.sessions.map(s => 
              s.id === clearedSession.id ? clearedSession : s
            ),
          }));
        }
      },

      // Eliminar sesión
      deleteSession: (sessionId) => {
        set((state) => {
          const newSessions = state.sessions.filter(s => s.id !== sessionId);
          const newCurrentSession = state.currentSession?.id === sessionId 
            ? null 
            : state.currentSession;

          return {
            sessions: newSessions,
            currentSession: newCurrentSession,
          };
        });
      },

      // Actualizar título de sesión
      updateSessionTitle: (sessionId, title) => {
        set((state) => ({
          sessions: state.sessions.map(s => 
            s.id === sessionId ? { ...s, title, updatedAt: new Date() } : s
          ),
          currentSession: state.currentSession?.id === sessionId 
            ? { ...state.currentSession, title, updatedAt: new Date() }
            : state.currentSession,
        }));
      },
    }),
    {
      name: 'aws-propuestas-chat-store',
      partialize: (state) => ({
        sessions: state.sessions,
        selectedModel: state.selectedModel,
        mode: state.mode,
      }),
    }
  )
);
