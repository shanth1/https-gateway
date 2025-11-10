#!/usr/bin/env bash
# Forces an attempt to renew all managed SSL certificates.

echo "### Forcing renewal attempt for all certificates... ###"
docker-compose run --rm certbot renew --force-renewal
