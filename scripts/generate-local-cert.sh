#!/usr/bin/env bash
# Generates a self-signed certificate for local development.

# Check if openssl is installed
if ! command -v openssl &> /dev/null; then
  echo "Error: openssl is not installed." >&2
  echo "On macOS/Linux, it's usually pre-installed. On Windows, use WSL or Git Bash." >&2
  exit 1
fi

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
  echo "Usage: ./scripts/generate-local-cert.sh <domain>"
  echo "Example: ./scripts/generate-local-cert.sh localhost"
  echo "Example for a custom domain: ./scripts/generate-local-cert.sh my-app.local"
  exit 1
fi

# Create ssl directory if it doesn't exist
mkdir -p nginx/ssl

KEY_FILE="nginx/ssl/${DOMAIN}.key"
CERT_FILE="nginx/ssl/${DOMAIN}.crt"

if [ -f "$KEY_FILE" ] && [ -f "$CERT_FILE" ]; then
  echo "Certificate for $DOMAIN already exists in nginx/ssl/."
  exit 0
fi

echo "Generating self-signed certificate for $DOMAIN..."

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CERT_FILE" \
  -subj "/C=XX/ST=Local/L=Local/O=LocalDev/OU=Dev/CN=$DOMAIN"

echo "Done! Certificate and key saved in nginx/ssl/"
