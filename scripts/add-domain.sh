#!/bin/bash
set -e

read -p "Введите домен (например, app.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "Ошибка: Домен не может быть пустым."
  exit 1
fi

read -p "Введите ваш email (для уведомлений от Let's Encrypt): " EMAIL
if [ -z "$EMAIL" ]; then
  echo "Ошибка: Email не может быть пустым."
  exit 1
fi

echo "Куда проксировать трафик?"
echo "  1) На другой Docker-контейнер в этой же сети (рекомендуется)"
echo "  2) На порт хост-машины (для сервисов без Docker)"
read -p "Выберите опцию [1-2]: " PROXY_TYPE

CONFIG_FILE="nginx/conf.d/${DOMAIN}.conf"
TEMPLATE_FILE=""
SERVICE_NAME=""
SERVICE_PORT=""

case $PROXY_TYPE in
  1)
    TEMPLATE_FILE="nginx/templates/production.conf.template"
    read -p "Введите имя сервиса Docker (из его docker-compose.yml): " SERVICE_NAME
    if [ -z "$SERVICE_NAME" ]; then echo "Ошибка: Имя сервиса не может быть пустым."; exit 1; fi
    read -p "Введите внутренний порт сервиса (например, 8000): " SERVICE_PORT
    if [ -z "$SERVICE_PORT" ]; then echo "Ошибка: Порт не может быть пустым."; exit 1; fi
    ;;
  2)
    TEMPLATE_FILE="nginx/templates/host.conf.template"
    SERVICE_NAME="host.docker.internal" # Специальное имя для прокси на хост
    read -p "Введите порт на хост-машине (например, 8080): " SERVICE_PORT
    if [ -z "$SERVICE_PORT" ]; then echo "Ошибка: Порт не может быть пустым."; exit 1; fi
    ;;
  *)
    echo "Ошибка: Неверный выбор."
    exit 1
    ;;
esac

echo "### Создаем конфигурацию Nginx для домена $DOMAIN... ###"
cp $TEMPLATE_FILE $CONFIG_FILE

# Используем sed для замены плейсхолдеров
sed -i.bak "s/<DOMAIN>/$DOMAIN/g" $CONFIG_FILE
sed -i.bak "s/<SERVICE_NAME>/$SERVICE_NAME/g" $CONFIG_FILE
sed -i.bak "s/<SERVICE_PORT>/$SERVICE_PORT/g" $CONFIG_FILE
rm $CONFIG_FILE.bak # Удаляем бэкап-файл

echo "### Перезагружаем Nginx, чтобы применить конфигурацию... ###"
docker-compose exec nginx nginx -s reload

echo "### Запрашиваем сертификат для $DOMAIN... ###"
STAGING_ARG=""
read -p "Использовать staging-сервер Let's Encrypt (для тестов)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    STAGING_ARG="--staging"
fi

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot \
  $STAGING_ARG \
  -d $DOMAIN \
  --email $EMAIL \
  --rsa-key-size 4096 \
  --agree-tos \
  --non-interactive # Добавляем флаг для неинтерактивного режима

# Проверяем, был ли успешно получен сертификат
if [ $? -ne 0 ]; then
  echo "### Ошибка получения сертификата. Удаляем созданный конфиг. ###"
  rm $CONFIG_FILE
  docker-compose exec nginx nginx -s reload
  exit 1
fi

echo "### Сертификат успешно получен! Перезагружаем Nginx для активации SSL... ###"
docker-compose exec nginx nginx -s reload

echo ""
echo "=================================================================="
echo "✅ Готово! Ваш сервис доступен по адресу: https://$DOMAIN"
echo "=================================================================="
