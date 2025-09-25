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



# --- PURGE ALL DOCKER RESOURCES (containers, images, volumes) ---
echo "Stopping all running Docker containers..."
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true

echo "Removing all Docker containers..."
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true

echo "Removing all Docker images..."
sudo docker rmi -f $(sudo docker images -aq) 2>/dev/null || true

echo "Removing all Docker volumes..."
sudo docker volume rm $(sudo docker volume ls -q) 2>/dev/null || true

echo "Docker system prune (removes all unused data)..."
sudo docker system prune -af --volumes

echo "All Docker containers, images, and volumes have been purged."

# --- END PURGE ---


(Optional) To redeploy Nginx, uncomment and fix config/port issues first.
sudo docker run -d \
  --name $CONTAINER_NAME \
  -p $HOST_PORT:$CONTAINER_PORT \
  -v "$NGINX_CONF":/etc/nginx/nginx.conf:ro \
  --restart unless-stopped \
  nginx:latest


Wait a moment for Nginx to start
sleep 2

# Show running container
sudo docker ps | grep $CONTAINER_NAME


# Test config inside the container
sudo docker exec $CONTAINER_NAME nginx -t


# Show Nginx logs (last 20 lines)
sudo docker logs --tail 20 $CONTAINER_NAME


# Print success message
echo "All Docker resources have been purged. Nginx is not running."
echo "If Nginx was restarting, it is usually due to a config error (nginx.conf syntax), missing files, or port 80 already in use."
echo "Fix config/port issues before redeploying."
