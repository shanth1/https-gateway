#!/bin/bash
echo "### Попытка принудительного продления сертификатов... ###"

docker-compose run --rm certbot renew --force-renewal
