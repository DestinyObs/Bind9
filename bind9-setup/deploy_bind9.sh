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

# Reload zones to ensure changes are live
sudo rndc reload || true

# Test DNS records from both localhost and server IP
function test_dns {
    local name=$1
    local expected=$2
    local server_ip=$3
    local result=$(dig +short @$server_ip $name)
    if [[ "$result" == "$expected" ]]; then
        echo "$name OK ($result) via $server_ip"
    else
        echo "$name FAIL (got $result, expected $expected) via $server_ip"
        exit 1
    fi
}

# Get server's main IP (assumes eth0 or ens* is main interface)
SERVER_IP=$(hostname -I | awk '{print $1}')

# Test from localhost and main IP
for ip in 127.0.0.1 $SERVER_IP; do
  test_dns prox1.cybacad.lab 192.168.3.8 $ip
  test_dns prox2.cybacad.lab 192.168.3.9 $ip
  test_dns prometheus.services.cybacad.lab 10.0.5.4 $ip
  test_dns grafana.services.cybacad.lab 10.0.5.5 $ip
  test_dns cks-master-1.cybacad.lab 192.168.32.8 $ip
  test_dns cks-master-2.cybacad.lab 192.168.32.9 $ip
  test_dns cks-worker-1.cybacad.lab 192.168.32.10 $ip
  test_dns cks-worker-2.cybacad.lab 192.168.32.3 $ip
  test_dns cks-worker-3.cybacad.lab 192.168.32.6 $ip
  test_dns cks-worker-4.cybacad.lab 192.168.32.7 $ip
  test_dns pfsense.cybacad.lab 192.168.32.1 $ip
  test_dns windows.cybacad.lab 192.168.32.2 $ip
  test_dns wazuh.cybacad.lab 40.10.10.10 $ip
  test_dns nodeexp1.cybacad.lab 10.0.5.2 $ip
  test_dns nodeexp2.cybacad.lab 10.0.5.3 $ip
  test_dns pulse.cybacad.lab 10.0.5.8 $ip
  test_dns ubuntumonitoring.cybacad.lab 10.0.5.7 $ip
  test_dns grafana.hq.cybacad.lab 10.0.5.5 $ip
  test_dns prometheus.hq.cybacad.lab 10.0.5.4 $ip
  test_dns grafana.services.cybacad.lab 10.0.5.5 $ip
  test_dns prometheus.services.cybacad.lab 10.0.5.4 $ip
  test_dns ns1.cybacad.lab 172.16.40.3 $ip
  test_dns ns1.hq.cybacad.lab 172.16.40.3 $ip
  test_dns ns1.services.cybacad.lab 172.16.40.3 $ip
  test_dns dns.services.cybacad.lab 172.16.40.3 $ip
  test_dns ns1.remote.cybacad.lab 172.16.40.3 $ip
  # Add more as needed
  echo "---"
done

echo "Bind9 deployment and test complete!"
echo "If nslookup/dig fails on clients, set 'nameserver 172.16.40.3' in /etc/resolv.conf or configure DHCP/pfSense to use this DNS."
