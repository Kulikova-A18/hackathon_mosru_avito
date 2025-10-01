import React from 'react';
import { useDrag } from 'react-dnd';
import {
  Paper,
  Typography,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Chip,
} from '@mui/material';
import {
  TextFields,
  TouchApp,
  Image,
  ViewCompact,
} from '@mui/icons-material';
import { UIComponent } from '../../types';

interface DraggableComponentProps {
  component: UIComponent;
}

const DraggableComponent: React.FC<DraggableComponentProps> = ({ component }) => {
  const [{ isDragging }, drag] = useDrag(() => ({
    type: 'COMPONENT',
    item: { type: component.type },
    collect: (monitor) => ({
      isDragging: monitor.isDragging(),
    }),
  }));

  const getIcon = (type: string) => {
    const icons: Record<string, React.ReactNode> = {
      text: <TextFields />,
      button: <TouchApp />,
      image: <Image />,
      container: <ViewCompact />,
    };
    return icons[type] || <TextFields />;
  };

  return (
    <ListItem
      ref={drag}
      sx={{
        opacity: isDragging ? 0.5 : 1,
        cursor: 'move',
        border: '1px solid',
        borderColor: 'divider',
        borderRadius: 1,
        mb: 1,
        '&:hover': {
          backgroundColor: 'action.hover',
        },
      }}
    >
      <ListItemIcon>
        {getIcon(component.type)}
      </ListItemIcon>
      <ListItemText 
        primary={component.name} 
        secondary={
          <Chip 
            label={component.type} 
            size="small" 
            variant="outlined" 
          />
        }
      />
    </ListItem>
  );
};

const ComponentPalette: React.FC = () => {
  const components: UIComponent[] = [
    {
      id: 'text',
      type: 'text',
      name: 'Text',
      icon: 'text',
      schema: {
        type: 'object',
        properties: {
          content: { type: 'string', title: 'Content' },
          size: { 
            type: 'string', 
            enum: ['small', 'medium', 'large'],
            title: 'Size'
          },
        },
      },
      defaultProps: { content: 'Sample Text', size: 'medium' },
    },
    {
      id: 'button',
      type: 'button',
      name: 'Button',
      icon: 'button',
      schema: {
        type: 'object',
        properties: {
          text: { type: 'string', title: 'Button Text' },
          variant: { 
            type: 'string', 
            enum: ['contained', 'outlined', 'text'],
            title: 'Variant'
          },
        },
      },
      defaultProps: { text: 'Click Me', variant: 'contained' },
    },
  ];

  return (
    <Paper sx={{ width: 280, p: 2, overflow: 'auto' }}>
      <Typography variant="h6" gutterBottom>
        Components
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        Drag components to canvas
      </Typography>
      
      <List dense>
        {components.map((component) => (
          <DraggableComponent
            key={component.id}
            component={component}
          />
        ))}
      </List>
    </Paper>
  );
};

export default ComponentPalette;
