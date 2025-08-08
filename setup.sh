#!/bin/bash

# Проверяем, существует ли сеть
if [ ! "$(docker network ls | grep web-gateway)" ]; then
  echo "Создаем Docker-сеть 'web-gateway'..."
  docker network create web-gateway
else
  echo "Docker-сеть 'web-gateway' уже существует."
fi

# Скачиваем рекомендованные параметры TLS от Certbot
if [ ! -f "certbot/live/options-ssl-nginx.conf" ] || [ ! -f "certbot/live/ssl-dhparams.pem" ]; then
  echo "Скачиваем рекомендованные параметры TLS..."
  mkdir -p certbot/live
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "certbot/live/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "certbot/live/ssl-dhparams.pem"
else
  echo "Параметры TLS уже на месте."
fi

echo ""
echo "Первоначальная настройка завершена!"
echo "Теперь вы можете запустить шлюз командой: docker-compose up -d"
echo "После этого используйте ./add-domain.sh для добавления ваших сервисов."
