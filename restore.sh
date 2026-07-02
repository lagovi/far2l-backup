#!/bin/bash

# Параметры запуска
GH_USER="${1}"
GH_REPO="${2}"
GH_BRANCH="${3:-main}"

if [ -z "$GH_USER" ] || [ -z "$GH_REPO" ]; then
    echo "Ошибка запуска. Использование:"
    echo "curl -sL <ссылка> | bash -s -- <пользователь> <репозиторий> [ветка]"
    exit 1
fi

FAR_CONFIG_DIR="$HOME/.config/far2l"
BACKUP_DIR="$HOME/far2l-config-backup"

echo "=== Начало восстановления настроек и развертывания инфраструктуры ==="
echo "Репозиторий источника: https://github.com/$GH_USER/$GH_REPO ($GH_BRANCH)"

# Безопасный перенос существующих настроек far2l в бэкап-папку, если они есть
if [ -d "$FAR_CONFIG_DIR" ]; then
    FAR_BAK="${FAR_CONFIG_DIR}_old_$(date +%Y%m%d_%H%M%S)"
    echo "Найдена существующая конфигурация far2l. Сохраняем её в: $FAR_BAK"
    mv "$FAR_CONFIG_DIR" "$FAR_BAK"
fi

# Безопасный перенос старой директории бэкапа, если она была
if [ -d "$BACKUP_DIR" ]; then
    DIR_BAK="${BACKUP_DIR}_old_$(date +%Y%m%d_%H%M%S)"
    echo "Найдена старая папка бэкапа. Сохраняем её в: $DIR_BAK"
    mv "$BACKUP_DIR" "$DIR_BAK"
fi

# Клонируем репозиторий бэкапа напрямую с GitHub
if command -v git &> /dev/null; then
    echo "Клонирование репозитория бэкапа с GitHub..."
    git clone -b "$GH_BRANCH" "https://github.com/${GH_USER}/${GH_REPO}.git" "$BACKUP_DIR"
else
    echo "Внимание: утилита git не найдена на целевом хосте. Выполняем установку через ZIP-архив..."
    if ! command -v unzip &> /dev/null; then
        echo "Ошибка: утилита 'unzip' не найдена. Пожалуйста, установите её."
        exit 1
    fi
    TEMP_ZIP="/tmp/far2l_backup_$$.zip"
    TEMP_DIR="/tmp/far2l_extracted_$$"
    ZIP_URL="https://github.com/${GH_USER}/${GH_REPO}/archive/refs/heads/${GH_BRANCH}.zip"
    
    curl -sL "$ZIP_URL" -o "$TEMP_ZIP"
    mkdir -p "$TEMP_DIR"
    unzip -q "$TEMP_ZIP" -d "$TEMP_DIR"
    EXTRACTED_SUBDIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    
    mkdir -p "$BACKUP_DIR"
    cp -r "$EXTRACTED_SUBDIR"/* "$BACKUP_DIR/"
    rm -rf "$TEMP_DIR" "$TEMP_ZIP"
    
    # Пытаемся инициализировать локальный Git на будущее
    cd "$BACKUP_DIR" || exit 1
    git init &>/dev/null
    git remote add origin "https://github.com/${GH_USER}/${GH_REPO}.git" &>/dev/null
    git branch -M "$GH_BRANCH" &>/dev/null
fi

# Копируем конфигурационные файлы в рабочую папку far2l
echo "Применение настроек far2l..."
mkdir -p "$FAR_CONFIG_DIR"

if [ -d "$BACKUP_DIR/settings" ]; then
    cp -r "$BACKUP_DIR/settings" "$FAR_CONFIG_DIR/"
fi

if [ -d "$BACKUP_DIR/plugins" ]; then
    cp -r "$BACKUP_DIR/plugins" "$FAR_CONFIG_DIR/"
fi

for file in palette.ini askpass.salt; do
    if [ -f "$BACKUP_DIR/$file" ]; then
        cp "$BACKUP_DIR/$file" "$FAR_CONFIG_DIR/"
    fi
done

# Делаем скрипт бэкапа исполняемым
if [ -f "$BACKUP_DIR/backup.sh" ]; then
    chmod +x "$BACKUP_DIR/backup.sh"
fi

echo "=== Восстановление успешно завершено ==="
echo "1. Настройки far2l восстановлены."
echo "2. Инфраструктура бэкапа развернута в $BACKUP_DIR и привязана к вашему репозиторию."
echo "Вы можете сразу вызывать резервное копирование по кнопке F2 в far2l."
