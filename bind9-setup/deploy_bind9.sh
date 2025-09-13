#!/bin/bash
set -e

# Directory where you cloned the repo
REPO_DIR="$(dirname "$0")"
BIND_DIR="/etc/bind"



# Ensure named service exists
if ! systemctl list-unit-files | grep -qw named.service; then
  echo "ERROR: named.service not found. Please install Bind9 first." >&2
  exit 1
fi

# Backup and copy named.conf.options only if not already present
if [ ! -f "$BIND_DIR/named.conf.options.bak" ]; then
  sudo cp "$BIND_DIR/named.conf.options" "$BIND_DIR/named.conf.options.bak"
fi
sudo cp "$REPO_DIR/named.conf.options" "$BIND_DIR/named.conf.options"

# Copy all zone and config files
sudo cp "$REPO_DIR"/db.* "$BIND_DIR/"
sudo cp "$REPO_DIR"/named.conf.local "$BIND_DIR/"

# Set permissions
sudo chown root:bind "$BIND_DIR"/db.*
sudo chmod 644 "$BIND_DIR"/db.*

# Check BIND configuration syntax
sudo named-checkconf

# Restart and enable BIND9 service (Ubuntu 24.04: named)
sudo systemctl restart named
sudo systemctl enable named

# Test DNS records
function test_dns {
    local name=$1
    local expected=$2
    local result=$(dig +short @$3 $name)
    if [[ "$result" == "$expected" ]]; then
        echo "$name OK ($result)"
    else
        echo "$name FAIL (got $result, expected $expected)"
        exit 1
    fi
}

echo "Testing DNS records..."
test_dns prox1.cybacad.lab 192.168.3.8 127.0.0.1
test_dns prox2.cybacad.lab 192.168.3.9 127.0.0.1
test_dns prometheus.services.cybacad.lab 10.0.5.4 127.0.0.1
test_dns grafana.services.cybacad.lab 10.0.5.5 127.0.0.1

echo "Bind9 deployment and test complete!"
