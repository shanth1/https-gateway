#!/usr/bin/env bash
# Performs initial setup for the gateway, such as creating the network and downloading TLS parameters.

set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Step 1: Create the external Docker network if it doesn't exist
if ! docker network inspect "${WEB_GATEWAY_NETWORK}" >/dev/null 2&>1; then
  echo "Creating Docker network '${WEB_GATEWAY_NETWORK}'..."
  docker network create "${WEB_GATEWAY_NETWORK}"
else
  echo "Docker network '${WEB_GATEWAY_NETWORK}' already exists."
fi

# Step 2: Check for and download TLS parameters if they are missing
CERT_VOLUME="${COMPOSE_PROJECT_NAME}_certbot_certs"

# We check for files *inside* the volume by running a temporary container.
# This is the most reliable method and does not depend on host-specific volume paths.
if docker volume inspect "$CERT_VOLUME" >/dev/null 2>&1 && \
   docker run --rm -v "${CERT_VOLUME}:/etc/letsencrypt" busybox:1.36 \
   [ -f "/etc/letsencrypt/options-ssl-nginx.conf" ] && \
   docker run --rm -v "${CERT_VOLUME}:/etc/letsencrypt" busybox:1.36 \
   [ -f "/etc/letsencrypt/ssl-dhparams.pem" ]; then
    echo "TLS parameters already exist in the Docker volume."
else
    echo "Downloading recommended TLS parameters..."
    mkdir -p ./.tmp_certs
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > ./.tmp_certs/options-ssl-nginx.conf
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > ./.tmp_certs/ssl-dhparams.pem

    echo "Copying parameters into the Docker volume..."
    # Use a temporary container to copy the downloaded files into the named volume
    docker run --rm \
      -v "$(pwd)/.tmp_certs:/tmp_certs:ro" \
      -v "${CERT_VOLUME}:/etc/letsencrypt" \
      busybox:1.36 cp /tmp_certs/options-ssl-nginx.conf /tmp_certs/ssl-dhparams.pem /etc/letsencrypt/

    rm -rf ./.tmp_certs
    echo "TLS parameters copied successfully."
fi

echo ""
echo "✅ Initial setup complete!"
echo "You can now start the gateway with: ./gateway.sh up"
