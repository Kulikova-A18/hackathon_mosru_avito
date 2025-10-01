#!/bin/bash
set -e

# Фиолетовая цветовая палитра
PURPLE='\033[0;35m'
DARK_PURPLE='\033[0;34m'
LIGHT_PURPLE='\033[1;35m'
MAGENTA='\033[1;95m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${LIGHT_PURPLE}[WARN]${NC} $1"
}

log_error() {
    echo -e "${MAGENTA}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${DARK_PURPLE}[SUCCESS]${NC} $1"
}

rebuild_backend() {
    log_info "Полная пересборка бэкенда..."
    
    # Удаляем старый бэкенд
    rm -rf backend
    mkdir backend
    cd backend

    # Создаем package.json
    cat > package.json << 'EOF'
{
  "name": "aether-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "nodemon --exitcrash server.js",
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

    # Получаем актуальный пароль из .env
    if [ -f "../.env" ]; then
        DB_PASSWORD_FROM_ENV=$(grep DB_PASSWORD ../.env | cut -d '=' -f2)
    else
        DB_PASSWORD_FROM_ENV="aether_password_073"
    fi

    log_info "🔑 Используем пароль из .env: $DB_PASSWORD_FROM_ENV"

    # Создаем server.js с правильным паролем
    cat > server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import pkg from 'pg';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

const { Pool } = pkg;
const app = express();
const port = process.env.PORT || 8080;

// Middleware - разрешаем все CORS запросы для разработки
app.use(cors({
    origin: ['http://localhost:3000', 'http://localhost:3001', 'http://127.0.0.1:3000', 'http://127.0.0.1:3001'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));

// PostgreSQL connection - ONLY REAL DATABASE
let pool;

const initializeDatabase = async () => {
    try {
        pool = new Pool({
            host: process.env.DB_HOST || 'localhost',
            port: process.env.DB_PORT || 5432,
            database: process.env.DB_NAME || 'aether_ui_db',
            user: process.env.DB_USER || 'aether_user',
            password: process.env.DB_PASSWORD,
        });

        // Test connection with actual query
        const client = await pool.connect();
        console.log('Testing database connection...');

        // Check if screens table exists and has data
        const screensResult = await client.query('SELECT COUNT(*) as count FROM screens');
        const componentsResult = await client.query('SELECT COUNT(*) as count FROM ui_components');
        
        console.log(`Screens in database: ${screensResult.rows[0].count}`);
        console.log(`Components in database: ${componentsResult.rows[0].count}`);
        
        client.release();
        console.log('Database connected successfully');
        return true;
    } catch (error) {
        console.error('DATABASE CONNECTION FAILED:', error.message);
        console.error('💡 Please check:');
        console.error(' - PostgreSQL is running');
        console.error(' - Database and user exist');
        console.error(' - Password is correct');
        console.error(' - Tables are created');
        process.exit(1); // Exit if database is not available
    }
};

// Health check with real database query
app.get('/api/health', async (req, res) => {
    try {
        const client = await pool.connect();
        const dbResult = await client.query('SELECT NOW() as time, version() as version');
        const screensCount = await client.query('SELECT COUNT(*) as count FROM screens');
        const componentsCount = await client.query('SELECT COUNT(*) as count FROM ui_components');
        client.release();

        res.json({
            status: 'OK',
            database: {
                connected: true,
                timestamp: dbResult.rows[0].time,
                version: dbResult.rows[0].version.split(' ')[1],
                screens: parseInt(screensCount.rows[0].count),
                components: parseInt(componentsCount.rows[0].count)
            }
        });
    } catch (error) {
        res.status(500).json({
            status: 'ERROR',
            error: 'Database connection failed',
            message: error.message
        });
    }
});

// Get all screens - ONLY FROM DATABASE
app.get('/api/screens', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, name, slug, version, config, is_active as "isActive", created_at as "createdAt", updated_at as "updatedAt" FROM screens ORDER BY created_at DESC`
        );
        console.log(`Returning ${result.rows.length} screens from database`);
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching screens:', error);
        res.status(500).json({ error: 'Failed to fetch screens', details: error.message });
    }
});

// Get screen by ID - ONLY FROM DATABASE
app.get('/api/screens/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT id, name, slug, version, config, is_active as "isActive" FROM screens WHERE id = $1`,
            [id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Screen not found' });
        }
        
        console.log(`📱 Returning screen: ${result.rows[0].name}`);
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error fetching screen:', error);
        res.status(500).json({ error: 'Failed to fetch screen', details: error.message });
    }
});

// Get screen by slug - ONLY FROM DATABASE
app.get('/api/screens/slug/:slug', async (req, res) => {
    try {
        const { slug } = req.params;
        console.log(`Fetching screen by slug: ${slug}`);
        
        const result = await pool.query(
            `SELECT id, name, slug, version, config, is_active as "isActive" FROM screens WHERE slug = $1 AND is_active = true`,
            [slug]
        );
        
        if (result.rows.length === 0) {
            console.log(`Screen not found with slug: ${slug}`);
            return res.status(404).json({ error: 'Screen not found' });
        }
        
        const screen = result.rows[0];
        console.log(`Screen found: ${screen.name}`);
        console.log(`Config type: ${typeof screen.config}, Config:`, screen.config);
        
        // Ensure config is properly parsed
        if (typeof screen.config === 'string') {
            try {
                screen.config = JSON.parse(screen.config);
                console.log('Config parsed from string');
            } catch (parseError) {
                console.error('Error parsing config:', parseError);
            }
        }
        
        res.json(screen);
    } catch (error) {
        console.error('Error fetching screen by slug:', error);
        res.status(500).json({ error: 'Failed to fetch screen', details: error.message });
    }
});

// Create new screen - SAVE TO DATABASE
app.post('/api/screens', async (req, res) => {
    try {
        const { name, slug, config, isActive = true } = req.body;
        
        if (!name || !slug) {
            return res.status(400).json({ error: 'Name and slug are required' });
        }

        // Ensure config is properly stringified for storage
        const configString = typeof config === 'string' ? config : JSON.stringify(config || {});
        
        const result = await pool.query(
            `INSERT INTO screens (name, slug, config, is_active) VALUES ($1, $2, $3, $4) RETURNING id, name, slug, version, config, is_active as "isActive", created_at as "createdAt"`,
            [name, slug, configString, isActive]
        );
        
        console.log(`Screen created: ${result.rows[0].name} (ID: ${result.rows[0].id})`);
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating screen:', error);
        if (error.code === '23505') { // Unique violation
            res.status(409).json({ error: 'Screen with this slug already exists' });
        } else {
            res.status(500).json({ error: 'Failed to create screen', details: error.message });
        }
    }
});

// Update screen - UPDATE IN DATABASE
app.put('/api/screens/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, slug, config, isActive } = req.body;

        // First, get current version for history
        const currentScreen = await pool.query(
            'SELECT version, config FROM screens WHERE id = $1',
            [id]
        );

        if (currentScreen.rows.length === 0) {
            return res.status(404).json({ error: 'Screen not found' });
        }

        // Save to versions table
        await pool.query(
            'INSERT INTO screen_versions (screen_id, version, config) VALUES ($1, $2, $3)',
            [id, currentScreen.rows[0].version, currentScreen.rows[0].config]
        );

        // Ensure config is properly stringified for storage
        const configString = typeof config === 'string' ? config : JSON.stringify(config || {});

        // Update screen
        const result = await pool.query(
            `UPDATE screens SET name = $1, slug = $2, config = $3, is_active = $4, version = version + 1, updated_at = NOW() WHERE id = $5 RETURNING id, name, slug, version, config, is_active as "isActive", updated_at as "updatedAt"`,
            [name, slug, configString, isActive, id]
        );
        
        console.log(`✏️ Screen updated: ${result.rows[0].name} (v${result.rows[0].version})`);
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error updating screen:', error);
        res.status(500).json({ error: 'Failed to update screen', details: error.message });
    }
});

// Get UI components - ONLY FROM DATABASE
app.get('/api/components', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, name, type, schema, created_at as "createdAt" FROM ui_components ORDER BY name`
        );
        console.log(`Returning ${result.rows.length} components from database`);
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching components:', error);
        res.status(500).json({ error: 'Failed to fetch components', details: error.message });
    }
});

// Analytics - SAVE TO DATABASE
app.post('/api/analytics/events', async (req, res) => {
    try {
        const { event_type, screen_id, element_id, user_id, session_id, platform, properties } = req.body;
        
        await pool.query(
            `INSERT INTO analytics_events (event_type, screen_id, element_id, user_id, session_id, platform, properties) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [event_type, screen_id, element_id, user_id, session_id, platform, properties]
        );
        
        console.log(`Analytics event recorded: ${event_type} for screen ${screen_id}`);
        res.status(201).json({ status: 'Event recorded' });
    } catch (error) {
        console.error('Error recording analytics:', error);
        res.status(500).json({ error: 'Failed to record analytics event', details: error.message });
    }
});

// Get screen versions - FROM DATABASE
app.get('/api/screens/:id/versions', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT id, version, config, created_at as "createdAt", created_by as "createdBy" FROM screen_versions WHERE screen_id = $1 ORDER BY version DESC`,
            [id]
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching screen versions:', error);
        res.status(500).json({ error: 'Failed to fetch screen versions', details: error.message });
    }
});

// Test endpoint for preview
app.get('/api/debug/screens', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT slug, name, is_active FROM screens ORDER BY name`
        );
        res.json({
            message: 'Available screens for preview',
            screens: result.rows
        });
    } catch (error) {
        console.error('Error fetching debug screens:', error);
        res.status(500).json({ error: 'Failed to fetch screens', details: error.message });
    }
});

// Initialize demo data
const initializeDemoData = async () => {
    try {
        // Check if demo screen exists
        const demoCheck = await pool.query(
            'SELECT COUNT(*) as count FROM screens WHERE slug = $1',
            ['demo-home']
        );

        if (parseInt(demoCheck.rows[0].count) === 0) {
            console.log('📝 Creating demo screens...');
            
            // Create demo home screen with proper JSON config
            const demoConfig = {
                components: [
                    {
                        type: "header",
                        props: {
                            text: "Добро пожаловать в THE LAST SIBERIA UI",
                            subtitle: "Конструктор пользовательских интерфейсов"
                        }
                    },
                    {
                        type: "text", 
                        props: {
                            text: "Это демонстрационный экран. Вы можете создавать и настраивать свои собственные интерфейсы с помощью нашего конструктора."
                        }
                    },
                    {
                        type: "card",
                        props: {
                            title: "Возможности системы",
                            content: "• Drag-and-drop конструктор\n• Предпросмотр в реальном времени\n• Версионность изменений\n• Аналитика использования"
                        }
                    },
                    {
                        type: "button",
                        props: {
                            text: "Начать работу"
                        }
                    },
                    {
                        type: "input",
                        props: {
                            placeholder: "Введите ваш email",
                            type: "email"
                        }
                    }
                ]
            };

            await pool.query(
                `INSERT INTO screens (name, slug, config, is_active) VALUES ($1, $2, $3, $4)`,
                ['Demo Home Screen', 'demo-home', JSON.stringify(demoConfig), true]
            );

            console.log('Demo screen created: demo-home');
        } else {
            console.log('Demo screen already exists: demo-home');
        }

        // Check if demo components exist
        const componentsCheck = await pool.query(
            'SELECT COUNT(*) as count FROM ui_components'
        );

        if (parseInt(componentsCheck.rows[0].count) === 0) {
            console.log('📝 Creating demo components...');
            
            const demoComponents = [
                {
                    name: 'Header',
                    type: 'header',
                    schema: {
                        type: 'object',
                        properties: {
                            text: { type: 'string', title: 'Заголовок' },
                            subtitle: { type: 'string', title: 'Подзаголовок' }
                        },
                        required: ['text']
                    }
                },
                {
                    name: 'Text',
                    type: 'text',
                    schema: {
                        type: 'object',
                        properties: {
                            text: { type: 'string', title: 'Текст' }
                        },
                        required: ['text']
                    }
                },
                {
                    name: 'Button',
                    type: 'button', 
                    schema: {
                        type: 'object',
                        properties: {
                            text: { type: 'string', title: 'Текст кнопки' }
                        },
                        required: ['text']
                    }
                },
                {
                    name: 'Input',
                    type: 'input',
                    schema: {
                        type: 'object',
                        properties: {
                            placeholder: { type: 'string', title: 'Подсказка' },
                            type: { 
                                type: 'string', 
                                title: 'Тип поля',
                                enum: ['text', 'email', 'password', 'number'],
                                default: 'text'
                            }
                        }
                    }
                },
                {
                    name: 'Card',
                    type: 'card',
                    schema: {
                        type: 'object', 
                        properties: {
                            title: { type: 'string', title: 'Заголовок карточки' },
                            content: { type: 'string', title: 'Содержимое' }
                        },
                        required: ['title']
                    }
                }
            ];

            for (const component of demoComponents) {
                await pool.query(
                    `INSERT INTO ui_components (name, type, schema) VALUES ($1, $2, $3)`,
                    [component.name, component.type, JSON.stringify(component.schema)]
                );
            }

            console.log('Demo components created');
        } else {
            console.log('Demo components already exist');
        }
    } catch (error) {
        console.error('Error initializing demo data:', error);
    }
};

// Initialize and start server
const startServer = async () => {
    console.log('Starting Aether Backend Server...');
    console.log('Database-only mode - No mock data');
    
    await initializeDatabase();
    await initializeDemoData();
    
    app.listen(port, () => {
        console.log('');
        console.log('Aether Backend Server running on port', port);
        console.log('💾 Database: PostgreSQL (REAL DATA ONLY)');
        console.log('Health check: http://localhost:' + port + '/api/health');
        console.log('Frontend: http://localhost:3000');
        console.log('Preview: http://localhost:3001');
        console.log('🐛 Debug: http://localhost:' + port + '/api/debug/screens');
        console.log('Demo: http://localhost:3001/?screen=demo-home');
        console.log('');
    });
};

startServer();
EOF

    # Создаем nodemon.json для корректной работы
    cat > nodemon.json << 'EOF'
{
  "watch": ["server.js", ".env"],
  "ext": "js,json",
  "ignore": ["node_modules/"],
  "exec": "node server.js",
  "restartable": "rs",
  "env": {
    "NODE_ENV": "development"
  }
}
EOF

    # Создаем .env файл с правильным паролем
    cat > .env << EOF
DB_HOST=localhost
DB_PORT=5432
DB_NAME=aether_ui_db
DB_USER=aether_user
DB_PASSWORD=$DB_PASSWORD_FROM_ENV
PORT=8080
EOF

    log_success "Бэкенд пересобран с паролем: $DB_PASSWORD_FROM_ENV"
    
    # Устанавливаем зависимости
    log_info "Установка зависимостей бэкенда..."
    npm install
    
    cd ..
}

setup_preview_server() {
    log_info "Настройка preview сервера..."
    
    # Создаем директорию для preview сервера
    rm -rf preview-server
    mkdir preview-server
    cd preview-server
    
    # Создаем package.json для preview сервера
    cat > package.json << 'EOF'
{
  "name": "aether-preview",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite --port 3001 --host",
    "build": "vite build"
  },
  "dependencies": {
    "vue": "^3.3.4",
    "vue-router": "^4.2.4"
  },
  "devDependencies": {
    "vite": "^4.4.5",
    "@vitejs/plugin-vue": "^4.3.4"
  }
}
EOF

    # Создаем vite.config.js
    cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 3001,
    host: true,
    cors: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        secure: false
      }
    }
  },
  define: {
    'process.env': {}
  }
})
EOF

    # Создаем базовую структуру preview приложения
    mkdir -p src/components
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>THE LAST SIBERIA UI Preview</title>
    <style>
        * {
            box-sizing: border-box;
        }
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .preview-container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
            min-height: 100vh;
        }
        .preview-header {
            background: linear-gradient(135deg, #6b46c1, #805ad5);
            color: white;
            padding: 20px;
            text-align: center;
        }
        .preview-content {
            padding: 30px;
            min-height: 400px;
        }
        .loading {
            text-align: center;
            padding: 60px 20px;
            color: #666;
        }
        .loading-spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #6b46c1;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .error {
            color: #d32f2f;
            padding: 30px;
            background: #ffebee;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
        }
        .success {
            color: #2e7d32;
            padding: 20px;
            background: #e8f5e8;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
        }
        .component {
            margin: 15px 0;
            padding: 20px;
            border: 2px dashed #e2e8f0;
            border-radius: 8px;
            transition: all 0.3s ease;
        }
        .component:hover {
            border-color: #6b46c1;
            background: #faf5ff;
        }
        .component-header {
            background: #f7fafc;
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 10px;
        }
        .component-button {
            background: linear-gradient(135deg, #6b46c1, #805ad5);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 16px;
            transition: all 0.3s ease;
        }
        .component-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(107, 70, 193, 0.4);
        }
        .component-input {
            width: 100%;
            padding: 12px;
            border: 2px solid #e2e8f0;
            border-radius: 6px;
            font-size: 16px;
            transition: border-color 0.3s ease;
        }
        .component-input:focus {
            outline: none;
            border-color: #6b46c1;
        }
        .debug-info {
            background: #f7fafc;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
            font-family: monospace;
            font-size: 14px;
        }
        .screens-list {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .screen-item {
            padding: 10px;
            margin: 5px 0;
            background: white;
            border-radius: 4px;
            cursor: pointer;
            border: 1px solid #e9ecef;
            transition: all 0.2s ease;
        }
        .screen-item:hover {
            border-color: #6b46c1;
            background: #faf5ff;
        }
    </style>
</head>
<body>
    <div id="app">
        <div class="preview-container">
            <div class="preview-header">
                <h1>👁️ THE LAST SIBERIA UI Preview</h1>
                <p>Режим предварительного просмотра</p>
            </div>
            
            <div class="preview-content">
                <div v-if="loading" class="loading">
                    <div class="loading-spinner"></div>
                    <h3>Загрузка preview...</h3>
                    <p>Подождите, идет загрузка конфигурации экрана</p>
                    <div class="debug-info" v-if="debugInfo">
                        {{ debugInfo }}
                    </div>
                </div>
                
                <div v-else-if="error" class="error">
                    <h3>Ошибка загрузки</h3>
                    <p>{{ error }}</p>
                    
                    <div class="screens-list" v-if="availableScreens.length > 0">
                        <h4>Доступные экраны:</h4>
                        <div 
                            v-for="screen in availableScreens" 
                            :key="screen.slug"
                            class="screen-item"
                            @click="loadScreen(screen.slug)"
                        >
                            <strong>{{ screen.name }}</strong> ({{ screen.slug }})
                        </div>
                    </div>
                    
                    <div class="debug-info">
                        URL: {{ currentUrl }}<br>
                        Screen Slug: {{ screenSlug }}<br>
                        Backend: {{ backendStatus }}
                    </div>
                    <button @click="retryLoading" class="component-button" style="margin-top: 15px;">
                        Повторить попытку
                    </button>
                </div>
                
                <div v-else-if="screenConfig" class="success">
                    <h3>Preview загружен успешно!</h3>
                    <p><strong>Экран:</strong> {{ screenConfig.name }} ({{ screenConfig.slug }})</p>
                    <p><strong>Версия:</strong> {{ screenConfig.version }}</p>
                    <div class="debug-info">
                        ID: {{ screenConfig.id }} | Active: {{ screenConfig.isActive }}
                    </div>
                </div>

                <div id="screen-content" v-if="screenConfig && !loading">
                    <!-- Динамический контент экрана -->
                </div>

                <div v-else-if="!loading && !error && !screenConfig" class="loading">
                    <h3>👋 Добро пожаловать в THE LAST SIBERIA UI Preview</h3>
                    <p>Для просмотра экрана добавьте параметр screen в URL:</p>
                    <div class="debug-info">
                        Пример: http://localhost:3001/?screen=demo-home
                    </div>
                    
                    <div class="screens-list" v-if="availableScreens.length > 0">
                        <h4>Или выберите один из доступных экранов:</h4>
                        <div 
                            v-for="screen in availableScreens" 
                            :key="screen.slug"
                            class="screen-item"
                            @click="loadScreen(screen.slug)"
                        >
                            <strong>{{ screen.name }}</strong> ({{ screen.slug }})
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script type="module" src="/src/main.js"></script>
</body>
</html>
EOF

    # Создаем основной JS файл
    cat > src/main.js << 'EOF'
import { createApp } from 'vue'

const app = createApp({
    data() {
        return {
            loading: false,
            error: null,
            screenConfig: null,
            screenSlug: null,
            currentUrl: window.location.href,
            backendStatus: 'checking...',
            debugInfo: null,
            availableScreens: []
        }
    },
    async mounted() {
        await this.checkBackendConnection()
        await this.loadAvailableScreens()
        await this.loadScreenPreview()
    },
    methods: {
        async checkBackendConnection() {
            try {
                const response = await fetch('http://localhost:8080/api/health')
                if (response.ok) {
                    this.backendStatus = 'connected ✅'
                } else {
                    this.backendStatus = 'error ❌'
                }
            } catch (err) {
                this.backendStatus = 'offline ❌'
            }
        },

        async loadAvailableScreens() {
            try {
                const response = await fetch('http://localhost:8080/api/debug/screens')
                if (response.ok) {
                    const data = await response.json()
                    this.availableScreens = data.screens.filter(screen => screen.is_active)
                    console.log('Available screens:', this.availableScreens)
                }
            } catch (err) {
                console.error('Error loading available screens:', err)
            }
        },

        async loadScreen(slug) {
            // Update URL without page reload
            const newUrl = `${window.location.origin}${window.location.pathname}?screen=${slug}`
            window.history.pushState({}, '', newUrl)
            this.currentUrl = newUrl
            this.screenSlug = slug
            await this.loadScreenPreview()
        },

        async loadScreenPreview() {
            try {
                this.loading = true
                this.error = null
                this.screenConfig = null
                this.debugInfo = 'Начинаем загрузку...'

                // Получаем screen slug из URL параметров
                const urlParams = new URLSearchParams(window.location.search)
                this.screenSlug = urlParams.get('screen')
                
                this.debugInfo = `Screen slug: ${this.screenSlug}`
                
                if (!this.screenSlug) {
                    this.loading = false
                    return
                }

                this.debugInfo = `Загружаем экран: ${this.screenSlug}`
                
                // Загружаем конфигурацию экрана с бэкенда
                const response = await fetch(`http://localhost:8080/api/screens/slug/${this.screenSlug}`)
                
                this.debugInfo = `Статус ответа: ${response.status}`
                
                if (!response.ok) {
                    if (response.status === 404) {
                        throw new Error(`Экран с slug "${this.screenSlug}" не найден. Проверьте правильность написания.`)
                    } else {
                        throw new Error(`Ошибка сервера: ${response.status}`)
                    }
                }

                this.screenConfig = await response.json()
                this.debugInfo = `Экран получен: ${this.screenConfig.name}`
                
                // Ensure config is properly parsed
                if (this.screenConfig.config && typeof this.screenConfig.config === 'string') {
                    try {
                        this.screenConfig.config = JSON.parse(this.screenConfig.config)
                        console.log('Config parsed from string in frontend')
                    } catch (parseError) {
                        console.error('Error parsing config in frontend:', parseError)
                    }
                }
                
                console.log('Screen config loaded:', this.screenConfig)
                
                // Даем время Vue обновиться перед рендерингом
                await this.$nextTick()
                this.renderScreenContent()
                
            } catch (err) {
                this.error = err.message
                console.error('Preview error:', err)
                this.debugInfo = `Ошибка: ${err.message}`
            } finally {
                this.loading = false
            }
        },

        renderScreenContent() {
            if (!this.screenConfig?.config) {
                console.warn('No screen config found:', this.screenConfig)
                const container = document.getElementById('screen-content')
                if (container) {
                    container.innerHTML = `
                        <div class="error">
                            <h3>Конфигурация экрана не найдена</h3>
                            <p>Экран "${this.screenConfig?.name}" не содержит конфигурации компонентов.</p>
                            <div class="debug-info">
                                Screen Data: ${JSON.stringify(this.screenConfig, null, 2)}
                            </div>
                        </div>
                    `
                }
                return
            }
            
            const container = document.getElementById('screen-content')
            if (!container) {
                console.error('Screen content container not found')
                return
            }

            try {
                // Очищаем контейнер
                container.innerHTML = ''

                // Динамически рендерим компоненты на основе конфигурации
                const config = this.screenConfig.config
                console.log('Rendering screen config:', config)
                
                if (config.components && Array.isArray(config.components) && config.components.length > 0) {
                    config.components.forEach((component, index) => {
                        const element = this.createComponentElement(component, index)
                        container.appendChild(element)
                    })
                } else {
                    container.innerHTML = `
                        <div class="component">
                            <div style="text-align: center; color: #666; padding: 40px;">
                                <h3>Нет компонентов для отображения</h3>
                                <p>Конфигурация экрана не содержит компонентов</p>
                                <div class="debug-info">
                                    Config: ${JSON.stringify(config, null, 2)}
                                </div>
                            </div>
                        </div>
                    `
                }

                console.log('Preview загружен успешно:', this.screenConfig.name)
            } catch (err) {
                console.error('Ошибка рендеринга:', err)
                this.error = 'Ошибка отображения preview: ' + err.message
            }
        },

        createComponentElement(component, index) {
            const element = document.createElement('div')
            element.className = `component component-${component.type}`
            element.setAttribute('data-component-type', component.type)
            element.setAttribute('data-component-index', index)

            // Базовый рендеринг по типу компонента
            switch (component.type) {
                case 'header':
                    element.innerHTML = `
                        <div class="component-header">
                            <h1 style="margin: 0; color: #2d3748; font-size: 2em;">${component.props?.text || 'Заголовок'}</h1>
                            ${component.props?.subtitle ? `<p style="margin: 10px 0 0 0; color: #718096; font-size: 1.2em;">${component.props.subtitle}</p>` : ''}
                        </div>
                    `
                    break
                case 'text':
                    element.innerHTML = `
                        <div style="color: #4a5568; line-height: 1.6; font-size: 16px;">
                            ${component.props?.text || 'Текстовый контент'}
                        </div>
                    `
                    break
                case 'button':
                    element.innerHTML = `
                        <button class="component-button">
                            ${component.props?.text || 'Кнопка'}
                        </button>
                    `
                    break
                case 'input':
                    element.innerHTML = `
                        <input 
                            class="component-input" 
                            type="${component.props?.type || 'text'}" 
                            placeholder="${component.props?.placeholder || 'Введите текст...'}"
                            value="${component.props?.value || ''}"
                        >
                    `
                    break
                case 'card':
                    element.innerHTML = `
                        <div style="border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; background: white;">
                            <h3 style="margin: 0 0 15px 0; color: #2d3748;">${component.props?.title || 'Карточка'}</h3>
                            <p style="margin: 0; color: #718096; white-space: pre-line;">${component.props?.content || 'Содержимое карточки'}</p>
                        </div>
                    `
                    break
                default:
                    element.innerHTML = `
                        <div style="text-align: center; color: #a0aec0; padding: 20px;">
                            <div style="font-size: 2em;">🔧</div>
                            <h4 style="margin: 10px 0; color: #718096;">Компонент: ${component.type}</h4>
                            <div class="debug-info" style="font-size: 12px; margin-top: 10px;">
                                ${JSON.stringify(component.props, null, 2)}
                            </div>
                        </div>
                    `
            }

            return element
        },

        retryLoading() {
            this.loadScreenPreview()
        }
    }
})

app.mount('#app')
EOF

    log_success "Preview сервер настроен"
    
    # Устанавливаем зависимости
    log_info "Установка зависимостей preview сервера..."
    npm install
    
    cd ..
}

start_services() {
    log_info "Запуск сервисов..."
    
    # Запускаем бэкенд в фоновом режиме
    cd backend
    log_info "Запуск бэкенда..."
    npm run dev &
    BACKEND_PID=$!
    cd ..
    
    # Даем время на запуск
    log_info "Ожидание запуска бэкенда..."
    sleep 10
    
    # Проверяем бэкенд
    log_info "Проверка бэкенда..."
    if curl -s http://localhost:8080/api/health > /dev/null; then
        log_success "Бэкенд запущен и отвечает"
        # Показываем детали здоровья
        HEALTH_RESPONSE=$(curl -s http://localhost:8080/api/health)
        echo "Health response: $HEALTH_RESPONSE"
        
        # Проверяем доступные экраны для preview
        log_info "Проверка доступных экранов..."
        SCREENS_RESPONSE=$(curl -s http://localhost:8080/api/debug/screens)
        echo "Available screens: $SCREENS_RESPONSE"
        
        # Проверяем конкретно демо экран
        log_info "Проверка демо экрана..."
        DEMO_RESPONSE=$(curl -s http://localhost:8080/api/screens/slug/demo-home)
        echo "Demo screen: $DEMO_RESPONSE"
    else
        log_error "Бэкенд не отвечает"
        log_info "Попытка перезапуска..."
        kill $BACKEND_PID 2>/dev/null || true
        sleep 2
        cd backend
        npm run dev &
        BACKEND_PID=$!
        cd ..
        sleep 5
        
        if curl -s http://localhost:8080/api/health > /dev/null; then
            log_success "Бэкенд запущен после перезапуска"
        else
            log_error "Критическая ошибка: бэкенд не может запуститься"
            return 1
        fi
    fi
    
    # Запускаем preview сервер
    log_info "Запуск preview сервера..."
    cd preview-server
    npm run dev &
    PREVIEW_PID=$!
    cd ..
    
    # Запускаем фронтенд
    log_info "Запуск фронтенда..."
    cd aether-admin
    npm run dev &
    FRONTEND_PID=$!
    cd ..
    
    sleep 8
    
    # Проверяем сервисы
    log_info "Проверка сервисов..."
    
    if curl -s http://localhost:3000 > /dev/null; then
        log_success "Фронтенд запущен (порт 3000)"
    else
        log_warn "Фронтенд может запускаться дольше обычного..."
    fi
    
    if curl -s http://localhost:3001 > /dev/null; then
        log_success "Preview сервер запущен (порт 3001)"
        
        # Показываем примеры preview ссылок
        echo ""
        log_info "Примеры preview ссылок:"
        log_info "   http://localhost:3001/?screen=demo-home"
        log_info "   http://localhost:3001/?screen=demo-home" 
        log_info "   http://localhost:3001/?screen=demo-home"
        echo ""
    else
        log_warn "Preview сервер может запускаться дольше обычного..."
    fi
    
    echo ""
    log_success "🎉 СИСТЕМА ЗАПУЩЕНА!"
    echo ""
    log_info "Бэкенд API: http://localhost:8080/api/health"
    log_info "Фронтенд: http://localhost:3000"
    log_info "Preview: http://localhost:3001"
    log_info "🐛 Debug: http://localhost:8080/api/debug/screens"
    log_info "База данных: PostgreSQL (localhost:5432)"
    echo ""
    log_info "💡 Откройте в браузере: http://localhost:3000"
    log_info "Демо экран: http://localhost:3001/?screen=demo-home"
    echo ""
    log_warn "Для остановки нажмите Ctrl+C"
    echo ""
    
    # Функция для graceful shutdown
    cleanup() {
        echo ""
        log_info "Остановка системы..."
        kill $BACKEND_PID $FRONTEND_PID $PREVIEW_PID 2>/dev/null || true
        log_success "Система остановлена"
        exit 0
    }
    
    # Ждем сигнала остановки
    trap cleanup INT TERM
    
    # Бесконечный цикл ожидания
    while true; do
        sleep 60
    done
}

main() {
    echo ""
    log_info "THE LAST SIBERIA UI System - Purple Theme"
    log_info "Полная пересборка и запуск системы..."
    echo ""
    
    rebuild_backend
    setup_preview_server
    start_services
}

main