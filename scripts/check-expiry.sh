#!/bin/bash

echo "### Проверка сроков действия SSL-сертификатов... ###"

docker-compose run --rm certbot certificates
