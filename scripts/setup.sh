#!/bin/bash
set -e

# Загружаем переменные из .env файла
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# Проверяем, существует ли сеть
if ! docker network inspect "${WEB_GATEWAY_NETWORK}" >/dev/null 2>&1; then
  echo "Создаем Docker-сеть '${WEB_GATEWAY_NETWORK}'..."
  docker network create "${WEB_GATEWAY_NETWORK}"
else
  echo "Docker-сеть '${WEB_GATEWAY_NETWORK}' уже существует."
fi

# Проверяем, существуют ли параметры TLS
# Мы делаем это, запуская временный контейнер, который имеет доступ к тому
# и проверяет наличие файлов. Это самый надежный способ.
if docker volume inspect "${COMPOSE_PROJECT_NAME}_certbot_certs" >/dev/null 2>&1 && \
   docker run --rm -v "${COMPOSE_PROJECT_NAME}_certbot_certs:/etc/letsencrypt" busybox:1.36 \
   [ -f "/etc/letsencrypt/options-ssl-nginx.conf" ] && \
   docker run --rm -v "${COMPOSE_PROJECT_NAME}_certbot_certs:/etc/letsencrypt" busybox:1.36 \
   [ -f "/etc/letsencrypt/ssl-dhparams.pem" ]; then
    echo "Параметры TLS уже на месте."
else
    echo "Скачиваем рекомендованные параметры TLS..."
    # Создаем временную папку для скачивания
    mkdir -p ./.tmp_certs
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > ./.tmp_certs/options-ssl-nginx.conf
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > ./.tmp_certs/ssl-dhparams.pem

    echo "Копируем параметры в Docker-том..."
    # Используем временный контейнер для копирования файлов в именованный том
    docker run --rm -v "$(pwd)/.tmp_certs:/tmp_certs" -v "${COMPOSE_PROJECT_NAME}_certbot_certs:/etc/letsencrypt" busybox:1.36 \
      cp /tmp_certs/options-ssl-nginx.conf /tmp_certs/ssl-dhparams.pem /etc/letsencrypt/

    # Удаляем временную папку
    rm -rf ./.tmp_certs
    echo "Параметры TLS успешно скопированы."
fi

echo ""
echo "✅ Первоначальная настройка завершена!"
echo "Теперь вы можете запустить шлюз командой: ./gateway.sh up"
