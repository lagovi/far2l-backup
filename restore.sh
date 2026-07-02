#!/bin/bash

# Параметры из аргументов запуска
GH_USER="${1}"
GH_REPO="${2}"
GH_BRANCH="${3:-main}"

if [ -z "$GH_USER" ] || [ -z "$GH_REPO" ]; then
    echo "Ошибка запуска. Использование:"
    echo "curl -sL <ссылка> | bash -s -- <пользователь> <репозиторий> [ветка]"
    exit 1
fi

FAR_CONFIG_DIR="$HOME/.config/far2l"
ZIP_URL="https://github.com/${GH_USER}/${GH_REPO}/archive/refs/heads/${GH_BRANCH}.zip"
TEMP_ZIP="/tmp/far2l_backup_$$.zip"
TEMP_DIR="/tmp/far2l_extracted_$$"

echo "=== Запуск восстановления настроек far2l ==="
echo "Репозиторий: $GH_USER/$GH_REPO (ветка: $GH_BRANCH)"

# Проверка unzip
if ! command -v unzip &> /dev/null; then
    echo "Ошибка: утилита 'unzip' не найдена. Пожалуйста, установите её (например: sudo apt install unzip)."
    exit 1
fi

# Если конфигурация far2l уже существует, сохраняем её копию во избежание потери данных
if [ -d "$FAR_CONFIG_DIR" ]; then
    BACKUP_PATH="${FAR_CONFIG_DIR}_old_$(date +%Y%m%d_%H%M%S)"
    echo "Обнаружена существующая папка настроек far2l. Переносим в $BACKUP_PATH"
    mv "$FAR_CONFIG_DIR" "$BACKUP_PATH"
fi

# Скачивание ZIP-архива
echo "Загрузка архива..."
HTTP_CODE=$(curl -sL -w "%{http_code}" "$ZIP_URL" -o "$TEMP_ZIP")

# Если ветка main выдала 404, пробуем master
if [ "$HTTP_CODE" -ne 200 ] && [ "$GH_BRANCH" = "main" ]; then
    echo "Файл в ветке 'main' не найден (HTTP $HTTP_CODE). Пробуем ветку 'master'..."
    GH_BRANCH="master"
    ZIP_URL="https://github.com/${GH_USER}/${GH_REPO}/archive/refs/heads/${GH_BRANCH}.zip"
    HTTP_CODE=$(curl -sL -w "%{http_code}" "$ZIP_URL" -o "$TEMP_ZIP")
fi

if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Ошибка: не удалось скачать архив настроек (HTTP код: $HTTP_CODE)."
    rm -f "$TEMP_ZIP"
    exit 1
fi

# Распаковка и применение
echo "Распаковка настроек..."
mkdir -p "$TEMP_DIR"
unzip -q "$TEMP_ZIP" -d "$TEMP_DIR"

# GitHub вкладывает файлы в поддиректорию вида <имя_репозитория>-<ветка>
EXTRACTED_SUBDIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [ -d "$EXTRACTED_SUBDIR/settings" ]; then
    mkdir -p "$FAR_CONFIG_DIR"
    cp -r "$EXTRACTED_SUBDIR/settings" "$FAR_CONFIG_DIR/"
    if [ -d "$EXTRACTED_SUBDIR/plugins" ]; then
        cp -r "$EXTRACTED_SUBDIR/plugins" "$FAR_CONFIG_DIR/"
    fi
    echo "Настройки успешно восстановлены!"
else
    echo "Ошибка: в архиве не найдена папка 'settings'."
    rm -rf "$TEMP_DIR" "$TEMP_ZIP"
    exit 1
fi

# Очистка временных файлов
rm -rf "$TEMP_DIR" "$TEMP_ZIP"
echo "=== Восстановление завершено ==="
