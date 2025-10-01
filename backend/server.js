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
