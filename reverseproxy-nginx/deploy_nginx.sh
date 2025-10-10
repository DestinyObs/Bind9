
#!/bin/bash
# ============================================================
# Nginx Reverse Proxy Deployment Script (Systemd Native)
# ============================================================
# This script will:
#   1. Stop and disable any previous Nginx Docker containers
#   2. Install Nginx via system package manager if not present
#   3. Deploy your custom nginx.conf to /etc/nginx/nginx.conf
#   4. Reload and enable Nginx via systemd
#   5. Test Nginx configuration and show status
# ============================================================

set -e

PROXY_DIR="$(dirname "$0")"
NGINX_CONF="$PROXY_DIR/nginx.conf"

# Step 1: Stop and remove any previous Nginx Docker containers
echo "Stopping and removing any previous Nginx Docker containers..."
sudo docker stop lab-nginx-reverseproxy 2>/dev/null || true
sudo docker rm lab-nginx-reverseproxy 2>/dev/null || true

# Step 2: Install Nginx via system package manager if not present
if ! command -v nginx >/dev/null 2>&1; then
    echo "Nginx not found. Installing..."
    sudo apt update
    sudo apt install -y nginx
fi

# Step 3: Deploy custom nginx.conf
echo "Deploying custom nginx.conf to /etc/nginx/nginx.conf..."
sudo cp "$NGINX_CONF" /etc/nginx/nginx.conf

# Step 4: Reload and enable Nginx via systemd
echo "Reloading Nginx configuration and enabling service..."
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Step 5: Show Nginx status and test
echo
echo "=== Nginx Service Status ==="
sudo systemctl status nginx --no-pager

echo
echo "=== Nginx Listening Ports ==="
sudo ss -tulnp | grep nginx || echo "Nginx is not listening on expected ports."

echo
echo "Deployment complete. Nginx reverse proxy is up and running via systemd."
echo "If you encounter issues, check /etc/nginx/nginx.conf syntax and port availability."
