#!/bin/bash
# ============================================================
# Standalone Nginx Reverse Proxy Deployment Script
# ============================================================
# This script will:
#   1. Purge all Docker containers, images, and volumes
#   2. Deploy an Nginx reverse proxy container with a custom config
#
# Prerequisites:
#   - Docker installed on the host
#   - Valid nginx.conf present in the same directory as this script
# ============================================================

set -e

# -------------------------------
# Define paths and variables
# -------------------------------
PROXY_DIR="$(dirname "$0")"
NGINX_CONF="$PROXY_DIR/nginx.conf"
CONTAINER_NAME="lab-nginx-reverseproxy"
HOST_PORT=80
CONTAINER_PORT=80

# -------------------------------
# Purge all Docker resources
# -------------------------------
echo "Stopping all running Docker containers..."
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true

echo "Removing all Docker containers..."
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true

echo "Removing all Docker images..."
sudo docker rmi -f $(sudo docker images -aq) 2>/dev/null || true

echo "Removing all Docker volumes..."
sudo docker volume rm $(sudo docker volume ls -q) 2>/dev/null || true

echo "Pruning Docker system (removes all unused data)..."
sudo docker system prune -af --volumes

echo "✅ All Docker containers, images, and volumes have been purged."

# -------------------------------
# Deploy Nginx reverse proxy
# -------------------------------
echo "Starting Nginx reverse proxy container..."
sudo docker run -d \
  --name "$CONTAINER_NAME" \
  -p $HOST_PORT:$CONTAINER_PORT \
  -v "$NGINX_CONF":/etc/nginx/nginx.conf:ro \
  --restart unless-stopped \
  nginx:latest

echo "✅ Nginx reverse proxy is now running on port $HOST_PORT."

# -------------------------------
# Post-deployment checks
# -------------------------------
# Wait briefly for Nginx to initialize
sleep 2

# Show running container
echo
echo "=== Running Containers ==="
sudo docker ps | grep "$CONTAINER_NAME" || echo "Nginx container not found."

# Test Nginx configuration inside the container
echo
echo "=== Testing Nginx Configuration ==="
sudo docker exec "$CONTAINER_NAME" nginx -t || {
  echo "❌ Nginx configuration test failed."
  exit 1
}

# Show Nginx logs (last 20 lines)
echo
echo "=== Nginx Logs (last 20 lines) ==="
sudo docker logs --tail 20 "$CONTAINER_NAME"

echo
echo "🎉 Deployment complete. Nginx reverse proxy is up and running."
echo "If the container keeps restarting, check nginx.conf syntax and port availability."
