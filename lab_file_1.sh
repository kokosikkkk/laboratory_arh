#!/bin/bash
echo "Вставте путь"
path="$1"
if [ $# -eq 0 ]; then
	echo "Путь не введен"
	exit 1
fi

if [ $# -gt 1 ]; then
	echo "Проверьте, введен ли только путь"
	exit 1
fi

if [ $# -z "$path" ]; then
	echo "Введите путь"
	exit 1
fi
if [! -e "$path"]; then
	echo "Путь введен некоректно или такого путь не существует"
	exit 1
else
	echo  "Идет проверка..."
