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
HOST_PORT=80
CONTAINER_PORT=80

# --- Let's Encrypt/HTTPS logic is disabled for now ---
# To re-enable, uncomment the relevant sections and update nginx.conf for HTTPS


# Stop and remove any existing container
sudo docker rm -f $CONTAINER_NAME 2>/dev/null || true


# Run the Nginx container with the custom config (HTTP only)
sudo docker run -d \
  --name $CONTAINER_NAME \
  -p $HOST_PORT:$CONTAINER_PORT \
  -v "$NGINX_CONF":/etc/nginx/nginx.conf:ro \
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


# Print success message
echo "Nginx reverse proxy is running on port $HOST_PORT (HTTP only)."
echo "Check your DNS and try accessing your lab domains via the proxy."
echo "Let's Encrypt/HTTPS is currently disabled for internal domains."
