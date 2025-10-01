import React from 'react';
import { Box } from '@mui/material';
import { LayoutNode } from '../../types';

interface CanvasElementProps {
  element: LayoutNode;
  isSelected: boolean;
  onClick: (element: LayoutNode, event: React.MouseEvent) => void;
  onUpdate: (elementId: string, updates: Partial<LayoutNode>) => void;
  children?: React.ReactNode;
}

const CanvasElement: React.FC<CanvasElementProps> = ({
  element,
  isSelected,
  onClick,
  children,
}) => {
  const handleClick = (event: React.MouseEvent) => {
    onClick(element, event);
  };

  return (
    <Box
      onClick={handleClick}
      sx={{
        position: 'relative',
        border: isSelected ? '2px solid' : '1px solid transparent',
        borderColor: isSelected ? 'primary.main' : 'transparent',
        borderRadius: 1,
        cursor: 'pointer',
        p: 1,
        backgroundColor: 'background.paper',
        '&:hover': {
          borderColor: isSelected ? 'primary.main' : 'grey.400',
        },
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <Box
          sx={{
            width: 8,
            height: 8,
            borderRadius: '50%',
            backgroundColor: 'primary.main',
          }}
        />
        <Box>
          <strong>{element.type}</strong>
          <Box sx={{ fontSize: '0.8rem', color: 'text.secondary' }}>
            {element.id}
          </Box>
        </Box>
      </Box>
      {children && (
        <Box sx={{ ml: 2, mt: 1 }}>
          {children}
        </Box>
      )}
    </Box>
  );
};

export default CanvasElement;
