#!/bin/bash

set -e

source .env 2>/dev/null || {
    echo "Файл .env не найден. Запустите сначала setup-aether-db.sh"
    exit 1
}

case "${1:-}" in
    "status")
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
            SELECT 'Таблицы:' as info;
            SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
            
            SELECT 'Экраны:' as info;
            SELECT id, name, slug FROM screens;
            
            SELECT 'Компоненты:' as info; 
            SELECT name, type FROM ui_components;
        "
        ;;
    "backup")
        backup_file="aether_backup_$(date +%Y%m%d_%H%M%S).sql"
        PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > $backup_file
        echo "Бэкап создан: $backup_file"
        ;;
    "restore")
        if [[ -z "$2" ]]; then
            echo "Укажите файл для восстановления: $0 restore backup_file.sql"
            exit 1
        fi
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME < "$2"
        echo "База восстановлена из: $2"
        ;;
    "logs")
        sudo tail -f /var/log/postgresql/postgresql-*.log
        ;;
    *)
        echo "Использование: $0 [команда]"
        echo "Команды:"
        echo "  status   - Показать статус базы"
        echo "  backup   - Создать бэкап"
        echo "  restore <file> - Восстановить из бэкапа"
        echo "  logs     - Показать логи PostgreSQL"
        ;;
esac

