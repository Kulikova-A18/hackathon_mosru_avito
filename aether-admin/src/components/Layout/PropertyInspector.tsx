import React from 'react';
import {
  Paper,
  Typography,
  TextField,
  Box,
  Switch,
  FormControlLabel,
  Divider,
} from '@mui/material';
import { LayoutNode } from '../../types';

interface PropertyInspectorProps {
  element: LayoutNode;
  onUpdate: (elementId: string, updates: Partial<LayoutNode>) => void;
}

const PropertyInspector: React.FC<PropertyInspectorProps> = ({ element, onUpdate }) => {
  const handlePropChange = (propName: string, value: any) => {
    onUpdate(element.id, {
      props: {
        ...element.props,
        [propName]: value,
      },
    });
  };

  const renderPropertyInput = (propName: string, value: any) => {
    const propType = typeof value;

    switch (propType) {
      case 'string':
        return (
          <TextField
            label={propName}
            value={value}
            onChange={(e) => handlePropChange(propName, e.target.value)}
            fullWidth
            size="small"
            margin="dense"
          />
        );

      case 'number':
        return (
          <TextField
            label={propName}
            type="number"
            value={value}
            onChange={(e) => handlePropChange(propName, Number(e.target.value))}
            fullWidth
            size="small"
            margin="dense"
          />
        );

      case 'boolean':
        return (
          <FormControlLabel
            control={
              <Switch
                checked={value}
                onChange={(e) => handlePropChange(propName, e.target.checked)}
              />
            }
            label={propName}
          />
        );

      default:
        return (
          <TextField
            label={propName}
            value={JSON.stringify(value)}
            onChange={(e) => {
              try {
                handlePropChange(propName, JSON.parse(e.target.value));
              } catch {
                handlePropChange(propName, e.target.value);
              }
            }}
            fullWidth
            size="small"
            margin="dense"
          />
        );
    }
  };

  return (
    <Paper sx={{ width: 320, p: 2, overflow: 'auto' }}>
      <Typography variant="h6" gutterBottom>
        Properties
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        {element.type} • {element.id}
      </Typography>

      <Divider sx={{ mb: 2 }} />

      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {Object.entries(element.props).map(([propName, value]) => (
          <Box key={propName}>
            {renderPropertyInput(propName, value)}
          </Box>
        ))}

        {Object.keys(element.props).length === 0 && (
          <Typography variant="body2" color="text.secondary" align="center">
            No properties to edit
          </Typography>
        )}
      </Box>
    </Paper>
  );
};

export default PropertyInspector;
