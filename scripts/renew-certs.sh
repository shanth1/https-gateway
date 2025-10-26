#!/bin/bash
echo "### Попытка принудительного продления сертификатов... ###"
docker-compose exec certbot renew
