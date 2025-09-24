#!/bin/bash
# Standalone Nginx Reverse Proxy Deployment Script
# This script will deploy and run the Nginx reverse proxy container with your custom config.
# It assumes you have already pulled the latest nginx image and are running on a Linux server with Docker installed.
# All commands use sudo for safety and permissions.

set -e


# Define paths
PROXY_DIR="$(dirname "$0")"
NGINX_CONF="$PROXY_DIR/nginx.conf"
CONTAINER_NAME="lab-nginx-reverseproxy"
HOST_HTTP_PORT=80
HOST_HTTPS_PORT=443
CONTAINER_HTTP_PORT=80
CONTAINER_HTTPS_PORT=443
LETSENCRYPT_DIR="/etc/letsencrypt"
EMAIL="destinyobueh14@gmail.com" # Change if needed

# List of all domains to get certificates for
DOMAINS=(
  grafana.cybacad.lab
  prometheus.cybacad.lab
  pulse.cybacad.lab
  wazuh.cybacad.lab
  pfsense.cybacad.lab
  prox1.cybacad.lab
  prox2.cybacad.lab
  nodeexp1.cybacad.lab
  nodeexp2.cybacad.lab
  windows.cybacad.lab
)


# Stop and remove any existing container
sudo docker rm -f $CONTAINER_NAME 2>/dev/null || true

# Ensure certbot is installed (for Ubuntu/Debian)
if ! command -v certbot >/dev/null; then
  echo "Certbot not found. Installing..."
  sudo apt-get update && sudo apt-get install -y certbot
fi

# Ensure recommended SSL options exist (first time only)
if [ ! -f "$LETSENCRYPT_DIR/options-ssl-nginx.conf" ]; then
  echo "Downloading recommended SSL options for Nginx..."
  sudo mkdir -p "$LETSENCRYPT_DIR"
  sudo wget -O "$LETSENCRYPT_DIR/options-ssl-nginx.conf" https://certbot.eff.org/docs/static/options-ssl-nginx.conf
  sudo wget -O "$LETSENCRYPT_DIR/ssl-dhparams.pem" https://certbot.eff.org/docs/static/ssl-dhparams.pem
fi

# Request/renew certificates for all domains (standalone mode, must stop Nginx container)
for domain in "${DOMAINS[@]}"; do
  if [ ! -d "$LETSENCRYPT_DIR/live/$domain" ]; then
    echo "Obtaining certificate for $domain..."
    sudo certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" -d "$domain"
  else
    echo "Certificate for $domain already exists. Skipping."
  fi
done


# Run the Nginx container with the custom config and Let's Encrypt certs
sudo docker run -d \
  --name $CONTAINER_NAME \
  -p $HOST_HTTP_PORT:$CONTAINER_HTTP_PORT \
  -p $HOST_HTTPS_PORT:$CONTAINER_HTTPS_PORT \
  -v "$NGINX_CONF":/etc/nginx/nginx.conf:ro \
  -v "$LETSENCRYPT_DIR":/etc/letsencrypt:ro \
  --restart unless-stopped \
  nginx:latest


# Wait a moment for Nginx to start
sleep 2

# Show running container
sudo docker ps | grep $CONTAINER_NAME


# Test config inside the container
sudo docker exec $CONTAINER_NAME nginx -t


# Show Nginx logs (last 20 lines)
sudo docker logs --tail 20 $CONTAINER_NAME

# Function to renew certificates and reload Nginx
renew_certs_and_reload() {
  echo "Renewing Let's Encrypt certificates..."
  for domain in "${DOMAINS[@]}"; do
    sudo certbot renew --deploy-hook "sudo docker exec $CONTAINER_NAME nginx -s reload"
  done
}

echo "To renew certificates in the future, run:"
echo "  sudo certbot renew --deploy-hook 'sudo docker exec $CONTAINER_NAME nginx -s reload'"


# Print success message
echo "Nginx reverse proxy is running on ports $HOST_HTTP_PORT (HTTP) and $HOST_HTTPS_PORT (HTTPS)."
echo "Check your DNS and try accessing your lab domains via the proxy."
echo "All HTTP traffic is redirected to HTTPS."
echo "Let's Encrypt certificates are used for all domains."
