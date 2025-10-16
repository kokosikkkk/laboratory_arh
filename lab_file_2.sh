#!/bin/bash

DIR="$1"
OCCUPANCY_THRESHOLD="$2"

if [ $# -lt 2 ]; then
    echo "Использование: $0 <путь> <порог>"
    exit 1
fi

if [ ! -d "$DIR" ]; then
    echo "Путь введен некорректно или такой путь не существует"
    exit 1
else
    echo "Путь введен корректно!"
fi

echo "Проверка заполненности заданной папки..."

function_occupancy() {
    local folder_size=$(du -sb "$DIR" | cut -f1)
    local device=$(df "$DIR" | awk 'NR==2 {print $1}')
    local disk_occupancy_b=$(df -B1 "$device" | awk 'NR==2 {print $2}')
    echo $((folder_size * 100 / disk_occupancy_b))
}
function_disk_occupancy() {
    local disk_usage=$(df -h "$DIR" | awk 'NR==2 {print $5}' | tr -d '%')
    echo "$disk_usage"
}

PERCENT=$(function_occupancy)
DISK=$(function_disk_occupancy)

echo "Размер папки: $(du -sh "$DIR" | cut -f1)"
echo "Заполненность папки: ${PERCENT}%"
echo "Заполненность диска: ${DISK}%"

if [ "$DISK" -gt 85 ]; then
    echo "Архивация невозможна, ваш диск переполнен!"
    exit 1
fi

if [[ ! "$OCCUPANCY_THRESHOLD" =~ ^[0-9]+$ ]] || [ "$OCCUPANCY_THRESHOLD" -lt 0 ] || [ "$OCCUPANCY_THRESHOLD" -gt 100 ]; then
    echo "Ошибка: порог должен быть числом от 0 до 100"
    exit 1
fi
echo "Установленный порог: ${OCCUPANCY_THRESHOLD}%"

function_n() {
    local file_count=$(find "$DIR" -maxdepth 1 -name "*.log" -type f | wc -l)
    local n=$((file_count * 10 / 100))
    if [ "$n" -lt 1 ]; then
        echo 1
    else
        echo "$n"
    fi
}

while [ "$PERCENT" -gt "$OCCUPANCY_THRESHOLD" ]; do
    DIR_BACKUP="${DIR}/backup/"
    if [ ! -d "$DIR_BACKUP" ]; then
        echo "$DIR_BACKUP не существует, создание $DIR_BACKUP"
        mkdir -p "$DIR_BACKUP"
    fi

    N=$(function_n)
    old_file=$(find "$DIR" -maxdepth 1 -name "*.log" -type f -printf "%T@ %p\n" | sort -n | head -n "$N" | cut -d' ' -f2-)
    if [ -n "$old_file" ]; then
        echo "=== Файлы подходящие для удаления ==="
        echo "$old_file"
        archive="${DIR_BACKUP}/log_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        tar -czf "$archive" --files-from=- <<< "$old_file" 2>/dev/null
        if [ $? -eq 0 ]; then
            xargs rm -f <<< "$old_file"
            echo "Архивация и удаление завершены"
            PERCENT=$(function_occupancy)
            echo "Проверка заполненности после архивации: ${PERCENT}%"
        else
            echo "Ошибка при архивации"
            exit 1
        fi
    else
        echo "Не найдены файлы для архивации"
        break
    fi
done

if [ "$PERCENT" -le "$OCCUPANCY_THRESHOLD" ]; then
    echo "Заполненность не превышает порог"
else
    echo "Невозможно больше архивировать"
fi