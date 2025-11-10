#!/bin/bash
set -e

# Получаем список доменов для выбора
DOMAINS=$(ls -1 nginx/conf.d/ | grep -v '.gitkeep' | sed 's/\.conf$//')

if [ -z "$DOMAINS" ]; then
  echo "Не найдено настроенных доменов для удаления."
  exit 0
fi

echo "Какой домен вы хотите удалить?"
select DOMAIN in $DOMAINS; do
  if [ -n "$DOMAIN" ]; then
    break
  else
    echo "Неверный выбор. Попробуйте еще раз."
  fi
done

read -p "Вы уверены, что хотите удалить домен $DOMAIN и все его сертификаты? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Удаление отменено."
    exit 1
fi

echo "### Шаг 1: Удаление сертификата Let's Encrypt для $DOMAIN... ###"
docker-compose run --rm certbot delete --cert-name "$DOMAIN"

if [ $? -ne 0 ]; then
  echo "### ВНИМАНИЕ: Не удалось удалить сертификат. Возможно, его не существовало. Продолжаем... ###"
fi

CONFIG_FILE="nginx/conf.d/${DOMAIN}.conf"
if [ -f "$CONFIG_FILE" ]; then
    echo "### Шаг 2: Удаление конфигурационного файла Nginx... ###"
    rm "$CONFIG_FILE"
else
    echo "### ВНИМАНИЕ: Конфигурационный файл $CONFIG_FILE не найден. ###"
fi


echo "### Шаг 3: Перезагрузка Nginx... ###"
docker-compose exec nginx nginx -s reload

echo ""
echo "=================================================================="
echo "✅ Готово! Домен $DOMAIN был успешно удален."
echo "=================================================================="
