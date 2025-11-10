#!/usr/bin/env bash
# Interactively removes a domain's configuration and its SSL certificate.

set -e

# Get a list of configured domains
DOMAINS=$(ls -1 nginx/conf.d/ | grep -v '\.gitkeep' | sed 's/\.conf$//')

if [ -z "$DOMAINS" ]; then
  echo "No configured domains found to remove."
  exit 0
fi

echo "Which domain would you like to remove?"
select DOMAIN in $DOMAINS; do
  if [ -n "$DOMAIN" ]; then
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

echo ""
read -p "Are you sure you want to remove $DOMAIN and its certificate? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Removal cancelled."
    exit 1
fi

echo ""
echo "### Step 1: Deleting Let's Encrypt certificate for $DOMAIN... ###"
docker-compose run --rm certbot delete --cert-name "$DOMAIN" || true
# We use '|| true' to prevent the script from exiting if certbot fails
# (e.g., if the certificate was already removed manually).

CONFIG_FILE="nginx/conf.d/${DOMAIN}.conf"
if [ -f "$CONFIG_FILE" ]; then
    echo "### Step 2: Removing Nginx configuration file... ###"
    rm "$CONFIG_FILE"
else
    echo "### WARNING: Nginx configuration file not found at $CONFIG_FILE. ###"
fi

echo "### Step 3: Reloading Nginx configuration... ###"
docker-compose exec nginx nginx -s reload

echo ""
echo "=================================================================="
echo "✅ Done! Domain $DOMAIN has been successfully removed."
echo "=================================================================="
