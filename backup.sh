#!/bin/bash

# Пути
REPO_DIR="$HOME/far2l-config-backup"
FAR_CONFIG_DIR="$HOME/.config/far2l"

echo "=== Запуск резервного копирования far2l ==="

# Создаем нужную структуру папок в бэкапе
mkdir -p "$REPO_DIR/settings"
mkdir -p "$REPO_DIR/plugins/NetRocks"

# 1. Копируем основные настройки
echo "Копирование настроек..."
if [ -d "$FAR_CONFIG_DIR/settings" ]; then
    cp -r "$FAR_CONFIG_DIR"/settings/* "$REPO_DIR/settings/"
fi

# 2. Копируем сайты NetRocks и вырезаем пароли
if [ -f "$FAR_CONFIG_DIR/plugins/NetRocks/sites.cfg" ]; then
    echo "Копирование сайтов NetRocks..."
    cp "$FAR_CONFIG_DIR/plugins/NetRocks/sites.cfg" "$REPO_DIR/plugins/NetRocks/sites.cfg"
    
    # Очистка зашифрованных и открытых паролей (Password и PasswordPlain)
    echo "Очистка паролей в файле бэкапа..."
    sed -E -i 's/^([[:space:]]*(Password|PasswordPlain)[[:space:]]*=[[:space:]]*).*/\1/' "$REPO_DIR/plugins/NetRocks/sites.cfg"
fi

# 3. Создаем базовый .gitignore
cat << 'GITIGNORE' > "$REPO_DIR/.gitignore"
.DS_Store
*.log
GITIGNORE

# 4. Отправка изменений в Git
cd "$REPO_DIR" || exit 1

# Инициализируем репозиторий, если этого еще не сделано
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
    # Пробуем отправить изменения (если remote настроен)
    if git remote | grep -q 'origin'; then
        echo "Отправка изменений на GitHub..."
        git push origin main || git push origin master
    else
        echo "Предупреждение: Удаленный репозиторий (origin) еще не настроен."
        echo "Пожалуйста, свяжите этот каталог с GitHub командой:"
        echo "  git remote add origin <URL_ВАШЕГО_ПУБЛИЧНОГО_РЕПО>"
    fi
fi

echo "=== Резервное копирование завершено ==="
read -p "Нажмите Enter для возврата в far2l..."
