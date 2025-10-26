#!/bin/bash

# Проверяем, установлен ли openssl
if ! [ -x "$(command -v openssl)" ]; then
  echo 'Ошибка: openssl не установлен.' >&2
  echo 'На macOS/Linux он обычно есть. На Windows установите его с WSL или Git Bash.' >&2
  exit 1
fi

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
  echo "Использование: ./generate-local-cert.sh <домен>"
  echo "Пример: ./generate-local-cert.sh localhost"
  echo "Пример для кастомного домена: ./generate-local-cert.sh my-app.local"
  exit 1
fi

# Создаем папки для сертификатов, если их нет
mkdir -p nginx/ssl

KEY_FILE="nginx/ssl/${DOMAIN}.key"
CERT_FILE="nginx/ssl/${DOMAIN}.crt"

if [ -f "$KEY_FILE" ] && [ -f "$CERT_FILE" ]; then
    echo "Сертификат для $DOMAIN уже существует в nginx/ssl/."
    exit 0
fi

echo "Генерируем самоподписанный сертификат для $DOMAIN..."

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CERT_FILE" \
  -subj "/C=RU/ST=Local/L=Local/O=LocalDev/OU=Dev/CN=$DOMAIN"

echo "Готово! Сертификат и ключ сохранены в папке nginx/ssl/"
