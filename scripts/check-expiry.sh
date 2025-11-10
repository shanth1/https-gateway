#!/usr/bin/env bash
# Checks the expiration status of all managed SSL certificates.

echo "### Checking SSL certificate expiration dates... ###"

# The 'certificates' command is the official and most reliable way
# to get information about certificates managed by certbot.
docker-compose run --rm certbot certificates
