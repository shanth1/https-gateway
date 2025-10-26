#!/bin/bash
set -e

source ./scripts/list-domains.sh
echo ""
read -p "Введите домен, который хотите удалить (из списка выше): " DOMAIN

if [ -z "$DOMAIN" ]; then
  echo "Ошибка: Домен не может быть пустым."
  exit 1
fi

CONFIG_FILE="nginx/conf.d/${DOMAIN}.conf"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Ошибка: Конфигурационный файл для домена $DOMAIN не найден."
  exit 1
fi

read -p "Вы уверены, что хотите удалить домен $DOMAIN и его сертификат? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo "### Удаляем сертификат для домена $DOMAIN... ###"
docker-compose run --rm certbot delete --cert-name $DOMAIN

echo "### Удаляем конфигурационный файл Nginx... ###"
rm $CONFIG_FILE

echo "### Перезагружаем Nginx... ###"
docker-compose exec nginx nginx -s reload

echo "✅ Домен $DOMAIN успешно удален."
