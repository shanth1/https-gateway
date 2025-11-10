#!/bin/bash

if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

show_help() {
  echo "Usage: ./gateway.sh [command]"
  echo ""
  echo "Commands:"
  echo "  setup         : Initial setup (create network, download TLS parameters)."
  echo "  up            : Start the production gateway (nginx + certbot)."
  echo "  down          : Stop the production gateway."
  echo "  up-local      : Start the gateway for local development."
  echo "  down-local    : Stop the local gateway."
  echo "  reload        : Reload Nginx configuration without stopping."
  echo "  logs          : Show Nginx logs."
  echo "  status        : Show the status of the containers."
  echo ""
  echo "  add           : Run the interactive script to add a new domain."
  echo "  remove        : Run the interactive script to remove a domain."
  echo "  list          : Show the list of configured domains."
  echo ""
  echo "  renew         : Force an attempt to renew all certificates."
  echo "  check-expiry  : Check the expiration dates of certificates for all domains."
  echo ""
}

if [ -z "$1" ]; then
  show_help
  exit 1
fi

COMMAND=$1
shift

case $COMMAND in
  setup)
    echo "--- Performing initial setup... ---"
    ./scripts/setup.sh
    ;;
  up)
    echo "--- Starting production gateway... ---"
    docker-compose up -d
    ;;
  down)
    echo "--- Stopping production gateway... ---"
    docker-compose down
    ;;
  up-local)
    echo "--- Starting local gateway... ---"
    docker-compose -f docker-compose.local.yaml up -d
    ;;
  down-local)
    echo "--- Stopping local gateway... ---"
    docker-compose -f docker-compose.local.yaml down
    ;;
  reload)
    echo "--- Reloading Nginx configuration... ---"
    docker-compose exec nginx nginx -s reload
    ;;
  logs)
    echo "--- Nginx logs (press Ctrl+C to exit)... ---"
    docker-compose logs -f nginx
    ;;
  status)
    echo "--- Gateway container status... ---"
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
    echo "--- Forcing certificate check and renewal... ---"
    ./scripts/renew-certs.sh
    ;;
  check-expiry)
    ./scripts/check-expiry.sh
    ;;
  *)
    echo "Error: Unknown command '$COMMAND'"
    echo ""
    show_help
    exit 1
    ;;
esac
