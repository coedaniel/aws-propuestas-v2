import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { v4 as uuid } from 'uuid';
import { ProyectoArquitecto, DatosProyecto, DocumentoGenerado, ServicioRapido } from '@/lib/types';

interface ArquitectoStore {
  // Estado actual
  proyectoActual: ProyectoArquitecto | null;
  proyectos: ProyectoArquitecto[];
  paso: number;
  isGeneratingDocuments: boolean;
  
  // Servicios rápidos
  serviciosRapidos: ServicioRapido[];
  
  // Acciones
  iniciarProyecto: (nombre: string, tipo: 'solucion-integral' | 'servicio-rapido') => void;
  actualizarDatos: (datos: Partial<DatosProyecto>) => void;
  siguientePaso: () => void;
  pasoAnterior: () => void;
  irAPaso: (paso: number) => void;
  completarProyecto: () => void;
  generarDocumentos: (bucketS3: string) => Promise<void>;
  cargarProyecto: (proyectoId: string) => void;
  eliminarProyecto: (proyectoId: string) => void;
  reiniciarProyecto: () => void;
}

// Servicios rápidos predefinidos
const SERVICIOS_RAPIDOS: ServicioRapido[] = [
  {
    id: 'ec2',
    nombre: 'Instancias EC2',
    descripcion: 'Implementación de instancias EC2 con configuración básica',
    categoria: 'compute',
    preguntas: [
      {
        id: 'tipo-instancia',
        pregunta: '¿Qué tipo de instancia necesitas?',
        tipo: 'select',
        opciones: ['t3.micro', 't3.small', 't3.medium', 't3.large', 'm5.large', 'm5.xlarge', 'c5.large', 'r5.large'],
        requerido: true,
        ayuda: 'Selecciona el tipo de instancia según tus necesidades de CPU, memoria y red'
      },
      {
        id: 'cantidad',
        pregunta: '¿Cuántas instancias necesitas?',
        tipo: 'number',
        requerido: true,
      },
      {
        id: 'sistema-operativo',
        pregunta: '¿Qué sistema operativo?',
        tipo: 'select',
        opciones: ['Amazon Linux 2', 'Ubuntu 20.04', 'Ubuntu 22.04', 'Windows Server 2019', 'Windows Server 2022'],
        requerido: true,
      },
      {
        id: 'almacenamiento',
        pregunta: '¿Cuánto almacenamiento EBS necesitas? (GB)',
        tipo: 'number',
        requerido: true,
      },
      {
        id: 'vpc-existente',
        pregunta: '¿Tienes una VPC existente?',
        tipo: 'boolean',
        requerido: true,
      }
    ]
  },
  {
    id: 'rds',
    nombre: 'Base de Datos RDS',
    descripcion: 'Implementación de base de datos RDS con configuración optimizada',
    categoria: 'database',
    preguntas: [
      {
        id: 'motor',
        pregunta: '¿Qué motor de base de datos necesitas?',
        tipo: 'select',
        opciones: ['MySQL', 'PostgreSQL', 'MariaDB', 'Oracle', 'SQL Server'],
        requerido: true,
      },
      {
        id: 'version',
        pregunta: '¿Qué versión del motor?',
        tipo: 'text',
        requerido: true,
        ayuda: 'Especifica la versión del motor de base de datos'
      },
      {
        id: 'clase-instancia',
        pregunta: '¿Qué clase de instancia RDS?',
        tipo: 'select',
        opciones: ['db.t3.micro', 'db.t3.small', 'db.t3.medium', 'db.m5.large', 'db.m5.xlarge', 'db.r5.large'],
        requerido: true,
      },
      {
        id: 'almacenamiento',
        pregunta: '¿Cuánto almacenamiento necesitas? (GB)',
        tipo: 'number',
        requerido: true,
      },
      {
        id: 'multi-az',
        pregunta: '¿Necesitas Multi-AZ para alta disponibilidad?',
        tipo: 'boolean',
        requerido: true,
      },
      {
        id: 'backups',
        pregunta: '¿Cuántos días de retención de backups?',
        tipo: 'number',
        requerido: true,
        ayuda: 'Entre 0 y 35 días'
      }
    ]
  },
  {
    id: 's3',
    nombre: 'Bucket S3',
    descripcion: 'Configuración de buckets S3 con políticas de seguridad',
    categoria: 'storage',
    preguntas: [
      {
        id: 'nombre-bucket',
        pregunta: '¿Cuál será el nombre del bucket?',
        tipo: 'text',
        requerido: true,
        ayuda: 'Debe ser único globalmente'
      },
      {
        id: 'proposito',
        pregunta: '¿Para qué usarás el bucket?',
        tipo: 'select',
        opciones: ['Almacenamiento general', 'Hosting web estático', 'Backup y archivos', 'Data Lake', 'Logs'],
        requerido: true,
      },
      {
        id: 'versionado',
        pregunta: '¿Necesitas versionado de objetos?',
        tipo: 'boolean',
        requerido: true,
      },
      {
        id: 'encriptacion',
        pregunta: '¿Qué tipo de encriptación?',
        tipo: 'select',
        opciones: ['AES-256', 'KMS', 'KMS con clave personalizada'],
        requerido: true,
      },
      {
        id: 'acceso-publico',
        pregunta: '¿Necesitas acceso público?',
        tipo: 'boolean',
        requerido: true,
      }
    ]
  },
  {
    id: 'vpc',
    nombre: 'VPC y Networking',
    descripcion: 'Configuración de VPC con subnets públicas y privadas',
    categoria: 'networking',
    preguntas: [
      {
        id: 'cidr',
        pregunta: '¿Qué rango CIDR para la VPC?',
        tipo: 'select',
        opciones: ['10.0.0.0/16', '172.16.0.0/16', '192.168.0.0/16', 'Personalizado'],
        requerido: true,
      },
      {
        id: 'azs',
        pregunta: '¿Cuántas Availability Zones?',
        tipo: 'select',
        opciones: ['2', '3', '4'],
        requerido: true,
      },
      {
        id: 'subnets-publicas',
        pregunta: '¿Necesitas subnets públicas?',
        tipo: 'boolean',
        requerido: true,
      },
      {
        id: 'subnets-privadas',
        pregunta: '¿Necesitas subnets privadas?',
        tipo: 'boolean',
        requerido: true,
      },
      {
        id: 'nat-gateway',
        pregunta: '¿Necesitas NAT Gateway?',
        tipo: 'boolean',
        requerido: true,
      }
    ]
  }
];

export const useArquitectoStore = create<ArquitectoStore>()(
  persist(
    (set, get) => ({
      // Estado inicial
      proyectoActual: null,
      proyectos: [],
      paso: 0,
      isGeneratingDocuments: false,
      serviciosRapidos: SERVICIOS_RAPIDOS,

      // Iniciar nuevo proyecto
      iniciarProyecto: (nombre, tipo) => {
        const nuevoProyecto: ProyectoArquitecto = {
          id: uuid(),
          nombre,
          tipo,
          estado: 'iniciado',
          datos: { nombre, tipo },
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        set((state) => ({
          proyectoActual: nuevoProyecto,
          proyectos: [nuevoProyecto, ...state.proyectos],
          paso: 1,
        }));
      },

      // Actualizar datos del proyecto
      actualizarDatos: (nuevosDatos) => {
        const { proyectoActual } = get();
        if (!proyectoActual) return;

        const proyectoActualizado = {
          ...proyectoActual,
          datos: { ...proyectoActual.datos, ...nuevosDatos },
          updatedAt: new Date(),
        };

        set((state) => ({
          proyectoActual: proyectoActualizado,
          proyectos: state.proyectos.map(p => 
            p.id === proyectoActualizado.id ? proyectoActualizado : p
          ),
        }));
      },

      // Siguiente paso
      siguientePaso: () => {
        set((state) => ({ paso: state.paso + 1 }));
      },

      // Paso anterior
      pasoAnterior: () => {
        set((state) => ({ paso: Math.max(0, state.paso - 1) }));
      },

      // Ir a paso específico
      irAPaso: (paso) => {
        set({ paso });
      },

      // Completar proyecto
      completarProyecto: () => {
        const { proyectoActual } = get();
        if (!proyectoActual) return;

        const proyectoCompletado = {
          ...proyectoActual,
          estado: 'completado' as const,
          updatedAt: new Date(),
        };

        set((state) => ({
          proyectoActual: proyectoCompletado,
          proyectos: state.proyectos.map(p => 
            p.id === proyectoCompletado.id ? proyectoCompletado : p
          ),
        }));
      },

      // Generar documentos
      generarDocumentos: async (bucketS3) => {
        const { proyectoActual } = get();
        if (!proyectoActual) return;

        set({ isGeneratingDocuments: true });

        try {
          const response = await fetch('/api/arquitecto/generar-documentos', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              proyectoId: proyectoActual.id,
              bucketS3,
              datos: proyectoActual.datos,
            }),
          });

          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }

          const data = await response.json();

          // Actualizar proyecto con documentos generados
          const proyectoConDocumentos = {
            ...proyectoActual,
            documentos: data.documentos,
            estado: 'completado' as const,
            updatedAt: new Date(),
          };

          set((state) => ({
            proyectoActual: proyectoConDocumentos,
            proyectos: state.proyectos.map(p => 
              p.id === proyectoConDocumentos.id ? proyectoConDocumentos : p
            ),
            isGeneratingDocuments: false,
          }));

        } catch (error) {
          console.error('Error generando documentos:', error);
          set({ isGeneratingDocuments: false });
          throw error;
        }
      },

      // Cargar proyecto existente
      cargarProyecto: (proyectoId) => {
        const proyecto = get().proyectos.find(p => p.id === proyectoId);
        if (proyecto) {
          set({ 
            proyectoActual: proyecto,
            paso: proyecto.estado === 'completado' ? 999 : 1,
          });
        }
      },

      // Eliminar proyecto
      eliminarProyecto: (proyectoId) => {
        set((state) => {
          const nuevosProyectos = state.proyectos.filter(p => p.id !== proyectoId);
          const nuevoProyectoActual = state.proyectoActual?.id === proyectoId 
            ? null 
            : state.proyectoActual;

          return {
            proyectos: nuevosProyectos,
            proyectoActual: nuevoProyectoActual,
            paso: nuevoProyectoActual ? state.paso : 0,
          };
        });
      },

      // Reiniciar proyecto actual
      reiniciarProyecto: () => {
        set({
          proyectoActual: null,
          paso: 0,
        });
      },
    }),
    {
      name: 'aws-propuestas-arquitecto-store',
      partialize: (state) => ({
        proyectos: state.proyectos,
      }),
    }
  )
);
