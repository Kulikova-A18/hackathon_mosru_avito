import React, { useState, useEffect } from 'react'
import { ThemeProvider, createTheme } from '@mui/material/styles'
import CssBaseline from '@mui/material/CssBaseline'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Workspace from './components/Layout/Workspace'
import { healthCheck } from './services/api'

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
})

const HomePage: React.FC = () => {
  const [status, setStatus] = useState<'loading' | 'connected' | 'error'>('loading')

  useEffect(() => {
    const init = async () => {
      try {
        await healthCheck()
        setStatus('connected')
      } catch (error) {
        setStatus('error')
      }
    }
    
    // Даем фронтенду время загрузиться
    setTimeout(init, 100)
  }, [])

  if (status === 'loading') {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        flexDirection: 'column',
        gap: '16px',
        fontFamily: 'Arial, sans-serif'
      }}>
        <div style={{ 
          width: '32px', 
          height: '32px', 
          border: '3px solid #f3f3f3',
          borderTop: '3px solid #1976d2',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite'
        }}></div>
        <div style={{ color: '#666' }}>Starting THE LAST SIBERIA UI...</div>
        <style>{`
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    )
  }

  if (status === 'error') {
    return (
      <div style={{ 
        padding: '40px', 
        textAlign: 'center',
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column'
      }}>
        <h1 style={{ color: '#ff4444' }}>⚠️ Connection Issue</h1>
        <p>Backend server is not available, but you can still use the builder.</p>
        <a href="/create" style={{ 
          padding: '10px 20px', 
          backgroundColor: '#1976d2', 
          color: 'white', 
          textDecoration: 'none',
          borderRadius: '4px',
          marginTop: '20px',
          display: 'inline-block'
        }}>
          Continue to Builder
        </a>
      </div>
    )
  }

  return (
    <div style={{ 
      padding: '40px', 
      textAlign: 'center',
      fontFamily: 'Arial, sans-serif',
      minHeight: '100vh',
      backgroundColor: '#f5f5f5'
    }}>
      <div style={{ 
        maxWidth: '600px', 
        margin: '0 auto',
        padding: '40px',
        backgroundColor: 'white',
        borderRadius: '8px',
        boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
      }}>
        <h1 style={{ color: '#1976d2', marginBottom: '20px', fontSize: '2.5rem' }}>
          🚀 THE LAST SIBERIA UI Admin
        </h1>
        <p style={{ fontSize: '18px', marginBottom: '10px', color: '#666' }}>
          Backend-Driven UI Platform
        </p>
        <p style={{ fontSize: '14px', marginBottom: '20px', color: '#4caf50', padding: '8px', backgroundColor: '#f1f8e9', borderRadius: '4px' }}>
          ✅ Connected to backend server
        </p>
        <div style={{ marginTop: '30px' }}>
          <a 
            href="/create" 
            style={{ 
              padding: '12px 30px', 
              backgroundColor: '#1976d2', 
              color: 'white', 
              textDecoration: 'none',
              borderRadius: '6px',
              fontSize: '16px',
              display: 'inline-block',
              fontWeight: 'bold'
            }}
          >
            Open Visual Builder
          </a>
        </div>
      </div>
    </div>
  )
}

const App: React.FC = () => {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/edit/:screenId" element={<Workspace />} />
          <Route path="/create" element={<Workspace />} />
        </Routes>
      </Router>
    </ThemeProvider>
  )
}

export default App
