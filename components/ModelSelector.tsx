import React from 'react';

interface ModelSelectorProps {
  selectedModel: string;
  onModelChange: (model: string) => void;
  disabled?: boolean;
  compact?: boolean;
}

const MODELS = [
  {
    id: 'amazon.nova-pro-v1:0',
    name: 'Nova Pro',
    description: 'Conversaciones complejas y análisis profundo',
    icon: '🚀',
    color: 'text-blue-600'
  },
  {
    id: 'anthropic.claude-3-haiku-20240307-v1:0',
    name: 'Claude Haiku',
    description: 'Rápido para tareas técnicas y arquitectura',
    icon: '⚡',
    color: 'text-green-600'
  }
];

export default function ModelSelector({ selectedModel, onModelChange, disabled, compact = false }: ModelSelectorProps) {
  if (compact) {
    return (
      <div className="flex items-center space-x-4 mb-3">
        <span className="text-sm font-medium text-gray-700">Modelo:</span>
        <select
          value={selectedModel}
          onChange={(e) => onModelChange(e.target.value)}
          disabled={disabled}
          className="text-sm border border-gray-300 rounded-md px-3 py-1 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        >
          {MODELS.map((model) => (
            <option key={model.id} value={model.id}>
              {model.icon} {model.name}
            </option>
          ))}
        </select>
      </div>
    );
  }

  return (
    <div className="mb-4 p-3 bg-gray-50 rounded-lg border">
      <div className="flex flex-wrap gap-3">
        {MODELS.map((model) => (
          <label key={model.id} className="flex items-center space-x-2 cursor-pointer">
            <input
              type="radio"
              name="model"
              value={model.id}
              checked={selectedModel === model.id}
              onChange={(e) => onModelChange(e.target.value)}
              disabled={disabled}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500"
            />
            <div className="flex items-center space-x-1">
              <span className="text-lg">{model.icon}</span>
              <span className={`font-medium ${model.color}`}>{model.name}</span>
            </div>
          </label>
        ))}
      </div>
      <div className="mt-2 text-xs text-gray-500">
        {MODELS.find(m => m.id === selectedModel)?.description}
      </div>
    </div>
  );
}
