#!/bin/bash

# Пути
REPO_DIR="$HOME/far2l-config-backup"
FAR_CONFIG_DIR="$HOME/.config/far2l"

echo "=== Запуск резервного копирования far2l ==="

# Очищаем старые копии файлов в репозитории (кроме самого git и скриптов)
echo "Очистка старой структуры бэкапа..."
find "$REPO_DIR" -mindepth 1 -maxdepth 1 ! -name ".git" ! -name ".gitignore" ! -name "backup.sh" ! -name "restore.sh" -exec rm -rf {} +

# Создаем базовые директории
mkdir -p "$REPO_DIR/settings"

# Копируем основные настройки settings/
echo "Копирование настроек..."
if [ -d "$FAR_CONFIG_DIR/settings" ]; then
    cp -r "$FAR_CONFIG_DIR"/settings/* "$REPO_DIR/settings/"
fi

# Автоматический поиск и копирование всех конфигов плагинов (.ini и .cfg), кроме state.ini
echo "Поиск и копирование конфигураций плагинов..."
if [ -d "$FAR_CONFIG_DIR/plugins" ]; then
    cd "$FAR_CONFIG_DIR" || exit 1
    find plugins -type f \( -name "*.ini" -o -name "*.cfg" \) ! -name "state.ini" | while read -r file; do
        mkdir -p "$REPO_DIR/$(dirname "$file")"
        cp "$file" "$REPO_DIR/$file"
    done
fi

# Очистка паролей в сайтах NetRocks (если файл был скопирован)
if [ -f "$REPO_DIR/plugins/NetRocks/sites.cfg" ]; then
    echo "Очистка паролей в NetRocks sites.cfg..."
    sed -E -i 's/^([[:space:]]*(Password|PasswordPlain)[[:space:]]*=[[:space:]]*).*/\1/' "$REPO_DIR/plugins/NetRocks/sites.cfg"
fi

# Копируем файлы палитры и соли (если они существуют в корне настроек)
for file in palette.ini askpass.salt; do
    if [ -f "$FAR_CONFIG_DIR/$file" ]; then
        cp "$FAR_CONFIG_DIR/$file" "$REPO_DIR/$file"
    fi
done

# Создаем .gitignore
cat << 'GITIGNORE' > "$REPO_DIR/.gitignore"
.DS_Store
*.log
GITIGNORE

# Отправка изменений в Git
cd "$REPO_DIR" || exit 1

if [ ! -d ".git" ]; then
    echo "Инициализация Git-репозитория..."
    git init
    git branch -M main
fi

git add -A
if git diff-index --quiet HEAD --; then
    echo "Изменений в конфигурации не обнаружено."
else
    git commit -m "Автоматический бэкап: $(date '+%Y-%m-%d %H:%M:%S')"
    if git remote | grep -q 'origin'; then
        echo "Отправка изменений на GitHub..."
        git push origin main || git push origin master
    else
        echo "Предупреждение: Удаленный репозиторий (origin) еще не настроен."
    fi
fi

echo "=== Резервное копирование завершено ==="
read -p "Нажмите Enter для возврата в far2l..."
