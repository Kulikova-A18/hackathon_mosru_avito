import React from 'react';
import { Box, Typography, Paper, Button } from '@mui/material';
import { Add } from '@mui/icons-material';

const ScreenList: React.FC = () => {
  return (
    <Box sx={{ p: 4 }}>
      <Typography variant="h4" gutterBottom>
        Экранs
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography variant="body1">
          Список экранов будет отображаться здесь.
        </Typography>
        <Button 
          variant="contained" 
          startIcon={<Add />}
          sx={{ mt: 2 }}
        >
          Создать новый экран
        </Button>
      </Paper>
    </Box>
  );
};

export default ScreenList;
