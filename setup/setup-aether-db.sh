#!/bin/bash

set -e  # Выход при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для логирования
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Не запускайте скрипт от root! Запустите от обычного пользователя с sudo правами."
        exit 1
    fi
}

# Проверка ОС
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Не удалось определить дистрибутив Linux"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_warn "Скрипт тестировался на Ubuntu/Debian. Продолжаем, но могут быть проблемы..."
    fi
}

# Установка PostgreSQL
install_postgresql() {
    log_info "Обновление пакетов..."
    sudo apt update && sudo apt upgrade -y
    
    log_info "Установка PostgreSQL..."
    sudo apt install postgresql postgresql-contrib -y
    
    log_info "Проверка статуса PostgreSQL..."
    sudo systemctl status postgresql --no-pager
}

# Настройка базы данных
setup_database() {
    local db_name="aether_ui_db"
    local db_user="aether_user"
    local db_password="aether_password_073"  # Добавляем случайность
    
    log_info "Создание пользователя и базы данных..."
    
    # Создаем пользователя и базу данных
    sudo -u postgres psql -c "CREATE USER $db_user WITH PASSWORD '$db_password';" 2>/dev/null || log_warn "Пользователь уже существует"
    sudo -u postgres psql -c "CREATE DATABASE $db_name WITH OWNER $db_user;" 2>/dev/null || log_warn "База данных уже существует"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;"
    
    # Настройка аутентификации
    log_info "Настройка аутентификации..."
    PG_HBA_CONF=$(sudo find /etc/postgresql -name "pg_hba.conf" | head -1)
    if [[ -n "$PG_HBA_CONF" ]]; then
        sudo sed -i '/aether_user/d' "$PG_HBA_CONF"  # Удаляем старые записи
        echo "host    $db_name    $db_user     127.0.0.1/32           md5" | sudo tee -a "$PG_HBA_CONF"
        echo "host    $db_name    $db_user     ::1/128                md5" | sudo tee -a "$PG_HBA_CONF"
    else
        log_error "Не найден файл pg_hba.conf"
        exit 1
    fi
    
    # Настройка подключения
    PG_CONF=$(sudo find /etc/postgresql -name "postgresql.conf" | head -1)
    if [[ -n "$PG_CONF" ]]; then
        sudo sed -i "s/^#listen_addresses = .*/listen_addresses = 'localhost,127.0.0.1'/" "$PG_CONF"
    fi
    
    log_info "Перезапуск PostgreSQL..."
    sudo systemctl restart postgresql
    
    # Создание схемы
    create_schema "$db_name" "$db_user" "$db_password"
    
    # Сохранение конфигурации
    save_config "$db_name" "$db_user" "$db_password"
}

# Создание схемы базы данных
create_schema() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    
    log_info "Создание схемы базы данных..."
    
    # Создаем SQL файл
    cat > /tmp/create_aether_schema.sql << 'EOF'
-- Таблица для хранения UI компонентов
CREATE TABLE IF NOT EXISTS ui_components (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    type VARCHAR(50) NOT NULL,
    schema JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для экранов/страниц
CREATE TABLE IF NOT EXISTS screens (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    version INTEGER DEFAULT 1,
    config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для версионирования экранов
CREATE TABLE IF NOT EXISTS screen_versions (
    id SERIAL PRIMARY KEY,
    screen_id INTEGER REFERENCES screens(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    config JSONB NOT NULL,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(screen_id, version)
);

-- Таблица для шаблонов
CREATE TABLE IF NOT EXISTS templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    config JSONB NOT NULL,
    is_shared BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для A/B тестов
CREATE TABLE IF NOT EXISTS ab_tests (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    screen_id INTEGER REFERENCES screens(id),
    variant_a JSONB NOT NULL,
    variant_b JSONB NOT NULL,
    traffic_split DECIMAL(3,2) DEFAULT 0.5,
    is_active BOOLEAN DEFAULT false,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для аналитики
CREATE TABLE IF NOT EXISTS analytics_events (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    screen_id INTEGER REFERENCES screens(id),
    element_id VARCHAR(100),
    user_id VARCHAR(100),
    session_id VARCHAR(100),
    platform VARCHAR(20),
    properties JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для производительности
CREATE INDEX IF NOT EXISTS idx_screens_slug ON screens(slug);
CREATE INDEX IF NOT EXISTS idx_screens_active ON screens(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_screens_config ON screens USING gin(config);
CREATE INDEX IF NOT EXISTS idx_analytics_events_screen ON analytics_events(screen_id, event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at ON analytics_events(created_at);
CREATE INDEX IF NOT EXISTS idx_ab_tests_active ON ab_tests(is_active) WHERE is_active = true;

-- Функция и триггер для обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_screens_updated_at ON screens;
CREATE TRIGGER update_screens_updated_at BEFORE UPDATE ON screens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Заполняем начальными данными
INSERT INTO ui_components (name, type, schema) VALUES
('button', 'action', '{"type": "object", "properties": {"text": {"type": "string"}, "action": {"type": "string"}, "style": {"type": "string", "enum": ["primary", "secondary"]}}}'),
('text', 'display', '{"type": "object", "properties": {"content": {"type": "string"}, "size": {"type": "string", "enum": ["small", "medium", "large"]}, "color": {"type": "string"}}}'),
('image', 'media', '{"type": "object", "properties": {"url": {"type": "string"}, "width": {"type": "number"}, "height": {"type": "number"}, "alt": {"type": "string"}}}'),
('container', 'layout', '{"type": "object", "properties": {"direction": {"type": "string", "enum": ["row", "column"]}, "children": {"type": "array"}}}')
ON CONFLICT (name) DO NOTHING;

-- Демо-экран
INSERT INTO screens (name, slug, config) VALUES (
    'Demo Home Screen',
    'demo-home',
    '{
        "type": "container",
        "direction": "column",
        "children": [
            {
                "type": "text",
                "id": "welcome_text",
                "content": "Welcome to THE LAST SIBERIA UI!",
                "size": "large"
            },
            {
                "type": "button",
                "id": "demo_button",
                "text": "Click me!",
                "style": "primary",
                "action": "navigate_to_details"
            }
        ]
    }'::JSONB
) ON CONFLICT (slug) DO NOTHING;
EOF

    # Применяем схему
    PGPASSWORD=$db_password psql -h 127.0.0.1 -U "$db_user" -d "$db_name" -f /tmp/create_aether_schema.sql
    
    # Очистка
    rm -f /tmp/create_aether_schema.sql
}

# Сохранение конфигурации
save_config() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    
    log_info "Создание файла конфигурации..."
    
    cat > aether-db.env << EOF
# THE LAST SIBERIA UI Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$db_name
DB_USER=$db_user
DB_PASSWORD=$db_password
DB_URL=jdbc:postgresql://localhost:5432/$db_name

# Для Spring Boot приложения
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/$db_name
SPRING_DATASOURCE_USERNAME=$db_user
SPRING_DATASOURCE_PASSWORD=$db_password
EOF

    # Создаем .env для разработки
    cat > .env << EOF
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$db_name
DB_USER=$db_user
DB_PASSWORD=$db_password
EOF

    chmod 600 aether-db.env .env
}

# Проверка установки
verify_installation() {
    log_info "Проверка установки..."
    
    source .env 2>/dev/null || {
        log_error "Файл .env не найден"
        return 1
    }
    
    if PGPASSWORD=$DB_PASSWORD psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM screens;" &>/dev/null; then
        log_info "✅ База данных успешно настроена!"
        log_info "📊 Таблицы созданы и заполнены демо-данными"
    else
        log_error "❌ Ошибка при проверке базы данных"
        return 1
    fi
}

# Показ информации
show_info() {
    source .env 2>/dev/null || {
        log_error "Файл .env не найден"
        return 1
    }
    
    echo
    log_info "🎉 Установка завершена!"
    echo
    echo "📋 Информация о базе данных:"
    echo "   База данных: $DB_NAME"
    echo "   Пользователь: $DB_USER"
    echo "   Хост: $DB_HOST"
    echo "   Порт: $DB_PORT"
    echo
    echo "🔐 Файлы конфигурации созданы:"
    echo "   - aether-db.env (полная конфигурация)"
    echo "   - .env (для разработки)"
    echo
    echo "🚀 Пример подключения:"
    echo "   psql -h $DB_HOST -U $DB_USER -d $DB_NAME"
    echo
    echo "📊 Проверить демо-данные:"
    echo "   PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c \"SELECT name, slug FROM screens;\""
    echo
}

# Основная функция
main() {
    log_info "Запуск установки THE LAST SIBERIA UI Database..."
    
    check_root
    check_os
    install_postgresql
    setup_database
    verify_installation
    show_info
    
    log_info "Готово! База данных для THE LAST SIBERIA UI настроена."
}

# Обработка аргументов командной строки
case "${1:-}" in
    "recreate")
        log_info "Пересоздание базы данных..."
        # Добавьте логику пересоздания при необходимости
        ;;
    "cleanup")
        log_info "Очистка базы данных..."
        sudo -u postgres psql -c "DROP DATABASE IF EXISTS aether_ui_db;"
        sudo -u postgres psql -c "DROP USER IF EXISTS aether_user;"
        rm -f aether-db.env .env
        log_info "Очистка завершена"
        exit 0
        ;;
    "help"|"-h"|"--help")
        echo "Использование: $0 [команда]"
        echo "Команды:"
        echo "  recreate  - Пересоздать базу данных"
        echo "  cleanup   - Удалить базу данных и пользователя"
        echo "  help      - Показать эту справку"
        exit 0
        ;;
    *)
        main
        ;;
esac
