#!/bin/bash

# --- Главный скрипт управления HTTPS шлюзом ---

# Загружаем переменные из .env файла
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# Функция для вывода справки
show_help() {
  echo "Использование: ./gateway.sh [команда]"
  echo ""
  echo "Команды:"
  echo "  setup         : Первоначальная настройка (создать сеть, скачать TLS параметры)."
  echo "  up            : Запустить production-шлюз (nginx + certbot)."
  echo "  down          : Остановить production-шлюз."
  echo "  up-local      : Запустить шлюз для локальной разработки."
  echo "  down-local    : Остановить локальный шлюз."
  echo "  reload        : Перезагрузить конфигурацию Nginx без остановки."
  echo "  logs          : Показать логи Nginx."
  echo "  status        : Показать статус контейнеров."
  echo ""
  echo "  add           : Запустить интерактивный скрипт добавления нового домена."
  echo "  remove        : Запустить интерактивный скрипт удаления домена."
  echo "  list          : Показать список настроенных доменов."
  echo ""
  echo "  renew         : Принудительно попытаться продлить все сертификаты."
  echo "  check-expiry  : Проверить сроки действия сертификатов для всех доменов."
  echo ""
}

# Проверяем, существует ли команда
if [ -z "$1" ]; then
  show_help
  exit 1
fi

COMMAND=$1
shift # Сдвигаем аргументы, чтобы скрипты могли принимать свои

case $COMMAND in
  setup)
    echo "--- Выполняем первоначальную настройку... ---"
    ./scripts/setup.sh
    ;;
  up)
    echo "--- Запускаем production-шлюз... ---"
    docker-compose up -d
    ;;
  down)
    echo "--- Останавливаем production-шлюз... ---"
    docker-compose down
    ;;
  up-local)
    echo "--- Запускаем локальный шлюз... ---"
    docker-compose -f docker-compose.local.yml up -d
    ;;
  down-local)
    echo "--- Останавливаем локальный шлюз... ---"
    docker-compose -f docker-compose.local.yml down
    ;;
  reload)
    echo "--- Перезагружаем конфигурацию Nginx... ---"
    docker-compose exec nginx nginx -s reload
    ;;
  logs)
    echo "--- Логи Nginx (нажмите Ctrl+C для выхода)... ---"
    docker-compose logs -f nginx
    ;;
  status)
    echo "--- Статус контейнеров шлюза... ---"
    docker-compose ps
    ;;
  add)
    ./scripts/add-domain.sh
    ;;
  remove)
    ./scripts/remove-domain.sh
    ;;
  list)
    ./scripts/list-domains.sh
    ;;
  renew)
    echo "--- Принудительная проверка и продление сертификатов... ---"
    ./scripts/renew-certs.sh
    ;;
  check-expiry)
    ./scripts/check-expiry.sh
    ;;
  *)
    echo "Ошибка: Неизвестная команда '$COMMAND'"
    echo ""
    show_help
    exit 1
    ;;
esac
