import React, { useState, useCallback, useEffect } from 'react';
import { DndProvider } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';
import {
  Box,
  Typography,
  AppBar,
  Toolbar,
  Button,
  Chip,
  Snackbar,
  Alert,
} from '@mui/material';
import { Preview, Save } from '@mui/icons-material';
import ComponentPalette from './ComponentPalette';
import DesignCanvas from './DesignCanvas';
import PropertyInspector from './PropertyInspector';
import { ScreenConfig, LayoutNode } from '../../types';
import { getScreen, createScreen, updateScreen, healthCheck } from '../../services/api';

const Workspace: React.FC<{ screenId?: string }> = ({ screenId }) => {
  const [currentScreen, setCurrentScreen] = useState<ScreenConfig>({
    name: 'New Screen',
    slug: `screen-${Date.now()}`,
    version: 1,
    config: {
      id: 'root',
      type: 'container',
      props: { direction: 'column', spacing: 2 },
      children: [],
    },
    isActive: true,
  });

  const [selectedElement, setSelectedElement] = useState<LayoutNode | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Load screen if screenId is provided
  useEffect(() => {
    if (screenId) {
      loadScreen(screenId);
    }
    checkBackendHealth();
  }, [screenId]);

  const checkBackendHealth = async () => {
    try {
      await healthCheck();
    } catch (error) {
      setMessage({ type: 'error', text: 'Backend server is not available' });
    }
  };

  const loadScreen = async (id: string) => {
    try {
      setIsLoading(true);
      const screen = await getScreen(id);
      setCurrentScreen(screen);
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to load screen' });
    } finally {
      setIsLoading(false);
    }
  };

  const handleElementSelect = useCallback((element: LayoutNode | null) => {
    setSelectedElement(element);
  }, []);

  const handleElementUpdate = useCallback((elementId: string, updates: Partial<LayoutNode>) => {
    const updateNode = (node: LayoutNode): LayoutNode => {
      if (node.id === elementId) {
        return { ...node, ...updates };
      }
      if (node.children) {
        return {
          ...node,
          children: node.children.map(updateNode),
        };
      }
      return node;
    };

    setCurrentScreen(prev => ({
      ...prev,
      config: updateNode(prev.config),
    }));
  }, []);

  const handleSave = async () => {
    try {
      setIsLoading(true);
      let savedScreen: ScreenConfig;

      if (currentScreen.id) {
        // Update existing screen
        savedScreen = await updateScreen(currentScreen.id, currentScreen);
      } else {
        // Create new screen
        savedScreen = await createScreen(currentScreen);
      }

      setCurrentScreen(savedScreen);
      setMessage({ type: 'success', text: 'Screen saved successfully!' });
    } catch (error: any) {
      setMessage({ type: 'error', text: error.response?.data?.error || 'Failed to save screen' });
    } finally {
      setIsLoading(false);
    }
  };

  const handlePreview = () => {
    const previewUrl = `http://localhost:3001/preview?screen=${currentScreen.slug}`;
    window.open(previewUrl, '_blank');
  };

  if (isLoading && screenId) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        <Typography>Loading screen...</Typography>
      </Box>
    );
  }

  return (
    <DndProvider backend={HTML5Backend}>
      <Box sx={{ display: 'flex', height: '100vh', flexDirection: 'column' }}>
        <AppBar position="static" color="default" elevation={1}>
          <Toolbar>
            <Typography variant="h6" sx={{ flexGrow: 1 }}>
              THE LAST SIBERIA UI Builder {currentScreen.id && `- ${currentScreen.name}`}
            </Typography>
            <Chip 
              label={currentScreen.id ? "Editing" : "New Screen"} 
              color="info" 
              size="small" 
              sx={{ mr: 2 }}
            />
            <Button
              startIcon={<Preview />}
              onClick={handlePreview}
              sx={{ mr: 1 }}
            >
              Preview
            </Button>
            <Button
              startIcon={<Save />}
              onClick={handleSave}
              variant="contained"
              color="primary"
              disabled={isLoading}
            >
              {isLoading ? 'Saving...' : 'Save'}
            </Button>
          </Toolbar>
        </AppBar>

        <Box sx={{ display: 'flex', flexGrow: 1, overflow: 'hidden' }}>
          <ComponentPalette />
          
          <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ flexGrow: 1, p: 2, overflow: 'auto' }}>
              <DesignCanvas
                config={currentScreen.config}
                onElementSelect={handleElementSelect}
                onElementUpdate={handleElementUpdate}
                selectedElement={selectedElement}
              />
            </Box>
          </Box>

          {selectedElement && (
            <PropertyInspector
              element={selectedElement}
              onUpdate={handleElementUpdate}
            />
          )}
        </Box>

        <Snackbar
          open={!!message}
          autoHideDuration={6000}
          onClose={() => setMessage(null)}
        >
          <Alert 
            onClose={() => setMessage(null)} 
            severity={message?.type} 
            sx={{ width: '100%' }}
          >
            {message?.text}
          </Alert>
        </Snackbar>
      </Box>
    </DndProvider>
  );
};

export default Workspace;