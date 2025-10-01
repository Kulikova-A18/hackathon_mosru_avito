export interface UIComponent {
  id: string;
  type: string;
  name: string;
  icon: string;
  schema: ComponentSchema;
  defaultProps: Record<string, any>;
}

export interface ComponentSchema {
  type: 'object';
  properties: Record<string, PropertySchema>;
  required?: string[];
}

export interface PropertySchema {
  type: 'string' | 'number' | 'boolean' | 'array' | 'object';
  enum?: string[];
  default?: any;
  title?: string;
  description?: string;
}

export interface ScreenConfig {
  id?: string;
  name: string;
  slug: string;
  version: number;
  config: LayoutNode;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface LayoutNode {
  id: string;
  type: string;
  props: Record<string, any>;
  children?: LayoutNode[];
  constraints?: LayoutConstraints;
}

export interface LayoutConstraints {
  minWidth?: number;
  maxWidth?: number;
  minHeight?: number;
  maxHeight?: number;
}

export interface AnalyticsEvent {
  id: string;
  eventType: 'click' | 'view' | 'impression';
  screenId: string;
  elementId: string;
  userId: string;
  sessionId: string;
  platform: string;
  properties: Record<string, any>;
  createdAt: string;
}

export interface AISuggestion {
  id: string;
  type: 'layout' | 'styling' | 'content';
  description: string;
  confidence: number;
  suggestedChanges: Partial<LayoutNode>;
  reason: string;
}