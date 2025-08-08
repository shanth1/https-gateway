#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Использование: ./add-domain.sh <ДОМЕН> <EMAIL>"
  echo "Пример: ./add-domain.sh my-app.example.com admin@example.com"
  exit 1
fi

DOMAIN=$1
EMAIL=$2
STAGING_ARG=""

read -p "Использовать staging-сервер Let's Encrypt (для тестов)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    STAGING_ARG="--staging"
fi

echo "### Создаем временную конфигурацию Nginx для домена $DOMAIN... ###"
# Создаем временный конфиг только для HTTP-проверки
cat > nginx/conf.d/$DOMAIN.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 404; # Временно блокируем доступ ко всему остальному
    }
}
EOF

echo "### Перезагружаем Nginx, чтобы применить временную конфигурацию... ###"
docker-compose exec nginx nginx -s reload

echo "### Запрашиваем сертификат для $DOMAIN... ###"
docker-compose run --rm certbot certonly --webroot -w /var/www/certbot \
  $STAGING_ARG \
  -d $DOMAIN \
  --email $EMAIL \
  --rsa-key-size 4096 \
  --agree-tos \
  --force-renewal

# Проверяем, был ли успешно получен сертификат
if [ $? -ne 0 ]; then
  echo "### Ошибка получения сертификата. Удаляем временный конфиг. ###"
  rm nginx/conf.d/$DOMAIN.conf
  docker-compose exec nginx nginx -s reload
  exit 1
fi

echo "### Сертификат успешно получен! ###"
echo "### Удаляем временную конфигурацию. ###"
rm nginx/conf.d/$DOMAIN.conf
docker-compose exec nginx nginx -s reload

echo ""
echo "=================================================================="
echo "Что дальше?"
echo "1. Скопируйте nginx/nginx.conf.template в nginx/conf.d/$DOMAIN.conf"
echo "2. Отредактируйте новый файл, указав правильные:"
echo "   - <DOMAIN>       -> $DOMAIN"
echo "   - <SERVICE_NAME> -> имя контейнера вашего приложения"
echo "   - <SERVICE_PORT> -> внутренний порт вашего приложения"
echo "3. Перезагрузите Nginx: docker-compose exec nginx nginx -s reload"
echo "=================================================================="
