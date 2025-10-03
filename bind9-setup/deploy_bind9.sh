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

# Get server hostname and main IP
HOSTNAME=$(cat /etc/hostname | tr -d '\n')
# Force DMZ IP for testing
DMZ_IP="172.16.40.2"
SERVER_IP=$(ip -4 addr show | awk '/inet/ && !/127.0.0.1/ && !/docker/ {print $2}' | cut -d'/' -f1 | grep "$DMZ_IP" || echo "$DMZ_IP")

# Update A record for hostname in db.cybacad.lab
if ! grep -q "^$HOSTNAME[ \t]*IN[ \t]*A" "$REPO_DIR/db.cybacad.lab"; then
  echo "$HOSTNAME   IN      A       $SERVER_IP" | sudo tee -a "$REPO_DIR/db.cybacad.lab" > /dev/null
else
  sudo sed -i "/^$HOSTNAME[ \t]*IN[ \t]*A/c\$HOSTNAME   IN      A       $SERVER_IP" "$REPO_DIR/db.cybacad.lab"
fi

# Backup and copy named.conf.options only if not already present
if [ ! -f "$BIND_DIR/named.conf.options.bak" ]; then
  sudo cp "$BIND_DIR/named.conf.options" "$BIND_DIR/named.conf.options.bak"
fi
sudo cp "$REPO_DIR/named.conf.options" "$BIND_DIR/named.conf.options"

# Copy all zone and config files
sudo cp "$REPO_DIR"/db.* "$BIND_DIR/"
sudo cp "$REPO_DIR"/named.conf.local "$BIND_DIR/"
# Remove old monolithic reverse zone if present
sudo rm -f "$BIND_DIR/db.192"

# Set permissions
sudo chown root:bind "$BIND_DIR"/db.*
sudo chmod 644 "$BIND_DIR"/db.*

# Check BIND configuration syntax
sudo named-checkconf || { echo "named-checkconf failed"; exit 1; }

# Check all zone files for syntax
for zonefile in "$BIND_DIR"/db.*; do
  echo "Checking syntax for $zonefile..."
  sudo named-checkzone "$(basename "$zonefile")" "$zonefile" || { echo "Syntax error in $zonefile"; exit 1; }
done

# Restart and enable BIND9 service (Ubuntu 24.04: named)
sudo systemctl restart named
sudo systemctl enable named

# Print named service status
sudo systemctl status named --no-pager

# Reload zones to ensure changes are live
sudo rndc reload || true

# Test DNS records from both localhost and DMZ IP
function test_dns {
    local name=$1
    local expected=$2
    local server_ip=$3
    local result=$(dig +short @$server_ip $name | tr -d ' \t\n\r')
    local expected_clean=$(echo "$expected" | tr -d ' \t\n\r')
    if [[ "$result" == "$expected_clean" ]]; then
        echo "$name OK ($result) via $server_ip"
    else
        echo "$name FAIL (got '$result', expected '$expected_clean') via $server_ip"
        exit 1
    fi
}

function test_ptr {
    local ip=$1
    local expected=$2
    local server_ip=$3
    local result=$(dig +short -x $ip @$server_ip | tr -d ' \t\n\r')
    local expected_clean=$(echo "$expected" | tr -d ' \t\n\r')
    if [[ "$result" == "$expected_clean" ]]; then
        echo "$ip PTR OK ($result) via $server_ip"
    else
        echo "$ip PTR FAIL (got '$result', expected '$expected_clean') via $server_ip"
        exit 1
    fi
}

# List of test records (name expected_ip)
test_cases=(
  "prox1.cybacad.lab 192.168.3.8"
  "prox2.cybacad.lab 192.168.3.9"
  "prometheus.services.cybacad.lab 10.0.5.4"
  "grafana.services.cybacad.lab 10.0.5.5"
  "cks-master-1.cybacad.lab 192.168.32.8"
  "cks-master-2.cybacad.lab 192.168.32.9"
  "cks-worker-1.cybacad.lab 192.168.32.10"
  "cks-worker-2.cybacad.lab 192.168.32.3"
  "cks-worker-3.cybacad.lab 192.168.32.6"
  "cks-worker-4.cybacad.lab 192.168.32.7"
  "pfsense.cybacad.lab 192.168.32.1"
  "windows.cybacad.lab 192.168.32.2"
  "wazuh.cybacad.lab 40.10.10.10"
  "nodeexp1.cybacad.lab 10.0.5.2"
  "nodeexp2.cybacad.lab 10.0.5.3"
  "pulse.cybacad.lab 10.0.5.8"
  "grafana.hq.cybacad.lab 10.0.5.5"
  "prometheus.hq.cybacad.lab 10.0.5.4"
  "ns1.cybacad.lab 172.16.40.2"
  "ns1.hq.cybacad.lab 172.16.40.2"
  "ns1.services.cybacad.lab 172.16.40.2"
  "dns.services.cybacad.lab 172.16.40.2"
  "ns1.remote.cybacad.lab 172.16.40.2"
  "$HOSTNAME.cybacad.lab $SERVER_IP"
)

# List of PTR test records (ip expected_name)
ptr_cases=(
  "192.168.3.8 prox1.cybacad.lab."
  "192.168.3.9 prox2.cybacad.lab."
  "192.168.32.8 cks-master-1.cybacad.lab."
  "192.168.32.9 cks-master-2.cybacad.lab."
  "192.168.32.10 cks-worker-1.cybacad.lab."
  "192.168.32.3 cks-worker-2.cybacad.lab."
  "192.168.32.6 cks-worker-3.cybacad.lab."
  "192.168.32.7 cks-worker-4.cybacad.lab."
  "192.168.32.1 pfsense.cybacad.lab."
  "192.168.32.2 windows.cybacad.lab."
  "10.0.5.2 nodeexp1.cybacad.lab."
  "10.0.5.3 nodeexp2.cybacad.lab."
  "10.0.5.4 prometheus.cybacad.lab."
  "10.0.5.5 grafana.cybacad.lab."
  "10.0.5.8 pulse.cybacad.lab."
  "40.10.10.10 wazuh.cybacad.lab."
  "$SERVER_IP $HOSTNAME.cybacad.lab."
)

# Test from localhost and DMZ IP
for ip in 127.0.0.1 $DMZ_IP; do
  echo "Testing A records via $ip..."
  for test in "${test_cases[@]}"; do
    set -- $test
    test_dns "$1" "$2" "$ip"
  done
  echo "Testing PTR records via $ip..."
  for test in "${ptr_cases[@]}"; do
    set -- $test
    test_ptr "$1" "$2" "$ip"
  done
  echo "---"
done

echo "Bind9 deployment and test complete!"
echo "If nslookup/dig fails on clients, set 'nameserver 172.16.40.2' in /etc/resolv.conf or configure DHCP/pfSense to use this DNS."
