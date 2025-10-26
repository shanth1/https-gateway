#!/bin/bash

# Загружаем переменные из .env файла
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

CERT_DIR="${COMPOSE_PROJECT_NAME}_certbot_certs"

if ! docker volume inspect "$CERT_DIR" >/dev/null 2>&1; then
    echo "Том с сертификатами '$CERT_DIR' не найден. Шлюз запущен?"
    exit 1
fi

echo "### Проверка сроков действия SSL-сертификатов... ###"

DOMAINS=$(docker run --rm -v "${CERT_DIR}:/etc/letsencrypt" busybox:1.36 ls /etc/letsencrypt/live)

if [ -z "$DOMAINS" ]; then
    echo "Сертификаты не найдены."
    exit 0
fi

for domain in $DOMAINS; do
    if [ "$domain" == "README" ]; then
        continue
    fi
    echo "--- Домен: $domain ---"
    expiry_date=$(docker run --rm -v "${CERT_DIR}:/etc/letsencrypt" openssl:3 x509 -enddate -noout -in "/etc/letsencrypt/live/${domain}/fullchain.pem" | cut -d= -f2)

    if [[ $(uname) == "Darwin" ]]; then # macOS
        expiry_seconds=$(date -j -f "%b %d %T %Y %Z" "$expiry_date" "+%s")
    else # Linux
        expiry_seconds=$(date -d "$expiry_date" "+%s")
    fi

    now_seconds=$(date "+%s")
    days_left=$(( (expiry_seconds - now_seconds) / 86400 ))

    echo "Истекает: $expiry_date"
    echo "Дней осталось: $days_left"
    echo ""
done
