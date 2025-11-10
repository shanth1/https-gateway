#!/usr/bin/env bash
# Interactively adds a new domain, configures Nginx, and obtains a Let's Encrypt certificate.

set -e

# --- Helper Functions ---
print_header() {
  echo ""
  echo "### $1 ###"
}

print_success() {
  echo ""
  echo "=================================================================="
  echo "✅ Success! Your service is available at: https://$1"
  echo "=================================================================="
}

print_error() {
  echo "Error: $1" >&2
  exit 1
}

prompt_input() {
  local prompt_text=$1
  local var_name=$2
  read -p "$prompt_text" "$var_name"
  if [ -z "${!var_name}" ]; then
    print_error "Input cannot be empty."
  fi
}
# --- End Helper Functions ---


# --- Main Script ---
prompt_input "Enter the domain name (e.g., app.example.com): " DOMAIN
prompt_input "Enter your email (for Let's Encrypt notifications): " EMAIL

echo ""
echo "How should the traffic be proxied?"
echo "  1) To another Docker container in the same network (recommended)"
echo "  2) To a port on the host machine (for non-Docker services)"
echo "  3) To another server by IP address (e.g., 192.168.0.10)"
read -p "Choose an option [1-3]: " PROXY_TYPE

CONFIG_FILE="nginx/conf.d/${DOMAIN}.conf"
TEMPLATE_FILE=""
TARGET_ADDRESS=""
SERVICE_NAME=""
SERVICE_PORT=""

case $PROXY_TYPE in
  1) # Docker Container
    TEMPLATE_FILE="nginx/templates/production.conf.template"
    prompt_input "Enter the Docker service name (from its docker-compose.yaml): " SERVICE_NAME
    prompt_input "Enter the service's internal port (e.g., 8000): " SERVICE_PORT
    ;;
  2) # Host Machine
    TEMPLATE_FILE="nginx/templates/ip.conf.template"
    TARGET_ADDRESS="host.docker.internal"
    prompt_input "Enter the port on the host machine (e.g., 8080): " SERVICE_PORT
    ;;
  3) # Custom IP
    TEMPLATE_FILE="nginx/templates/ip.conf.template"
    prompt_input "Enter the target server's IP address: " TARGET_ADDRESS
    prompt_input "Enter the port on the target server: " SERVICE_PORT
    ;;
  *)
    print_error "Invalid selection."
    ;;
esac

print_header "Step 1: Preparing Nginx Configuration"
cp "$TEMPLATE_FILE" "$CONFIG_FILE"

sed -i.bak "s/<DOMAIN>/$DOMAIN/g" "$CONFIG_FILE"
if [ -n "$SERVICE_NAME" ]; then
  sed -i.bak "s/<SERVICE_NAME>/$SERVICE_NAME/g" "$CONFIG_FILE"
fi
if [ -n "$TARGET_ADDRESS" ]; then
  sed -i.bak "s/<TARGET_ADDRESS>/$TARGET_ADDRESS/g" "$CONFIG_FILE"
fi
sed -i.bak "s/<SERVICE_PORT>/$SERVICE_PORT/g" "$CONFIG_FILE"
rm "${CONFIG_FILE}.bak"

# Save the full config for later and create a temporary HTTP-only version
cp "$CONFIG_FILE" "${CONFIG_FILE}.with_ssl"
# This awk command extracts the first "server {}" block (the HTTP one)
awk '/server {/ && seen {exit} /server {/ {seen=1} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

print_header "Step 2: Reloading Nginx with Temporary HTTP Configuration"
docker-compose exec nginx nginx -s reload

print_header "Step 3: Requesting Let's Encrypt Certificate for $DOMAIN"
STAGING_ARG=""
read -p "Use Let's Encrypt staging server (for testing)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  STAGING_ARG="--staging"
fi

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot \
  $STAGING_ARG \
  -d "$DOMAIN" \
  --email "$EMAIL" \
  --rsa-key-size 4096 \
  --agree-tos \
  --non-interactive

if [ $? -ne 0 ]; then
  print_header "ERROR: Certificate acquisition failed. Cleaning up..."
  rm "$CONFIG_FILE"
  rm "${CONFIG_FILE}.with_ssl"
  docker-compose exec nginx nginx -s reload
  print_error "Failed to obtain the certificate."
fi

print_header "Step 4: Restoring Full HTTPS Configuration"
mv "${CONFIG_FILE}.with_ssl" "$CONFIG_FILE"

print_header "Step 5: Final Nginx Reload to Activate SSL"
docker-compose exec nginx nginx -s reload

print_success "$DOMAIN"
