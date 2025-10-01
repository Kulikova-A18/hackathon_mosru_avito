import React, { useCallback } from 'react';
import { useDrop } from 'react-dnd';
import {
  Box,
  Paper,
  Typography,
} from '@mui/material';
import CanvasElement from './CanvasElement';
import { LayoutNode } from '../../types';

interface DesignCanvasProps {
  config: LayoutNode;
  onElementSelect: (element: LayoutNode | null) => void;
  onElementUpdate: (elementId: string, updates: Partial<LayoutNode>) => void;
  selectedElement: LayoutNode | null;
}

const DesignCanvas: React.FC<DesignCanvasProps> = ({
  config,
  onElementSelect,
  onElementUpdate,
  selectedElement,
}) => {
  const [{ isOver }, drop] = useDrop(() => ({
    accept: 'COMPONENT',
    drop: (item: { type: string }) => {
      onElementUpdate(config.id, {
        children: [...(config.children || []), {
          id: `element_${Date.now()}`,
          type: item.type,
          props: getDefaultProps(item.type),
        }],
      });
    },
    collect: (monitor) => ({
      isOver: monitor.isOver(),
    }),
  }));

  const handleElementClick = useCallback((element: LayoutNode, event: React.MouseEvent) => {
    event.stopPropagation();
    onElementSelect(element);
  }, [onElementSelect]);

  const handleCanvasClick = useCallback(() => {
    onElementSelect(null);
  }, [onElementSelect]);

  const renderElement = (element: LayoutNode) => (
    <CanvasElement
      key={element.id}
      element={element}
      isSelected={selectedElement?.id === element.id}
      onClick={handleElementClick}
      onUpdate={onElementUpdate}
    >
      {element.children?.map(renderElement)}
    </CanvasElement>
  );

  return (
    <Paper
      ref={drop}
      sx={{
        flexGrow: 1,
        p: 2,
        backgroundColor: isOver ? 'action.hover' : 'background.default',
        minHeight: '600px',
        border: '2px dashed',
        borderColor: isOver ? 'primary.main' : 'transparent',
        position: 'relative',
        overflow: 'auto',
      }}
      onClick={handleCanvasClick}
    >
      <Typography 
        variant="body2" 
        color="text.secondary" 
        sx={{ 
          position: 'absolute',
          top: 8,
          left: 8,
        }}
      >
        Drop components here
      </Typography>

      <Box sx={{ minHeight: '100%' }}>
        {renderElement(config)}
      </Box>

      {(!config.children || config.children.length === 0) && (
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            height: '200px',
            color: 'text.secondary',
          }}
        >
          <Typography variant="h6">
            Drag components here to start building
          </Typography>
        </Box>
      )}
    </Paper>
  );
};

function getDefaultProps(componentType: string): Record<string, any> {
  const defaults: Record<string, any> = {
    text: { content: 'Sample Text', size: 'medium' },
    button: { text: 'Click Me', variant: 'contained' },
    image: { src: '', alt: 'Image', width: 200, height: 150 },
    container: { direction: 'column', spacing: 2 },
  };
  return defaults[componentType] || {};
}

export default DesignCanvas;