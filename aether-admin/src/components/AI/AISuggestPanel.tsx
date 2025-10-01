import React, { useState, useEffect } from 'react';
import {
  Paper,
  Typography,
  Box,
  Card,
  CardContent,
  Button,
  Chip,
  LinearProgress,
  Alert,
  List,
  ListItem,
  ListItemSecondaryAction,
  IconButton,
} from '@mui/material';
import {
  AutoAwesome,
  Check,
  Close,
} from '@mui/icons-material';
import { ScreenConfig, AISuggestion } from '../../types';

interface AISuggestPanelProps {
  screenConfig: ScreenConfig;
  onApplySuggestion: (elementId: string, updates: any) => void;
}

const AISuggestPanel: React.FC<AISuggestPanelProps> = ({
  screenConfig,
  onApplySuggestion,
}) => {
  const [suggestions, setSuggestions] = useState<AISuggestion[]>([]);
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  const analyzeScreen = async () => {
    setIsAnalyzing(true);
    
    setTimeout(() => {
      const mockSuggestions: AISuggestion[] = [
        {
          id: '1',
          type: 'layout',
          description: 'Consider using a grid layout for better mobile responsiveness',
          confidence: 0.87,
          suggestedChanges: {
            props: { direction: 'row', spacing: 3 },
          },
          reason: 'Grid layouts improve mobile experience by 23% based on analytics',
        },
      ];
      
      setSuggestions(mockSuggestions);
      setIsAnalyzing(false);
    }, 2000);
  };

  const handleApplySuggestion = (suggestion: AISuggestion) => {
    onApplySuggestion(screenConfig.config.id, suggestion.suggestedChanges);
    setSuggestions(prev => prev.filter(s => s.id !== suggestion.id));
  };

  const handleDismissSuggestion = (suggestionId: string) => {
    setSuggestions(prev => prev.filter(s => s.id !== suggestionId));
  };

  useEffect(() => {
    analyzeScreen();
  }, [screenConfig]);

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h4" gutterBottom>
        AI Suggestions
      </Typography>
      
      <Alert severity="info" sx={{ mb: 3 }}>
        AI analyzes your screen layout and best practices to provide optimization suggestions.
      </Alert>

      {isAnalyzing && (
        <Box sx={{ mb: 3 }}>
          <Typography variant="body2" gutterBottom>
            Analyzing screen...
          </Typography>
          <LinearProgress />
        </Box>
      )}

      <Button
        variant="outlined"
        startIcon={<AutoAwesome />}
        onClick={analyzeScreen}
        disabled={isAnalyzing}
        sx={{ mb: 3 }}
      >
        Re-analyze Screen
      </Button>

      {suggestions.length === 0 && !isAnalyzing && (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="body2" color="text.secondary">
            No suggestions available at the moment.
          </Typography>
        </Paper>
      )}

      <List>
        {suggestions.map((suggestion) => (
          <ListItem key={suggestion.id} component={Card} sx={{ mb: 2 }}>
            <CardContent sx={{ flexGrow: 1, p: 2 }}>
              <Typography variant="h6" gutterBottom>
                {suggestion.type} Suggestion
              </Typography>
              <Typography variant="body1" paragraph>
                {suggestion.description}
              </Typography>
              <Chip
                label={`${Math.round(suggestion.confidence * 100)}% confidence`}
                color="primary"
                size="small"
              />
            </CardContent>
            <ListItemSecondaryAction>
              <IconButton
                edge="end"
                color="success"
                onClick={() => handleApplySuggestion(suggestion)}
              >
                <Check />
              </IconButton>
              <IconButton
                edge="end"
                color="error"
                onClick={() => handleDismissSuggestion(suggestion.id)}
              >
                <Close />
              </IconButton>
            </ListItemSecondaryAction>
          </ListItem>
        ))}
      </List>
    </Box>
  );
};

export default AISuggestPanel;
