#!/bin/bash

# Bind9 DNS Server Setup Script
# DMZ deployment on 172.16.25.2

set -e

echo "Bind9 DNS Server Setup"
echo "DNS Server IP: 172.16.25.2 (DMZ)"
echo "Internal domain: site1.lab"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Update system and install Bind9
echo "Installing Bind9..."
apt update && apt upgrade -y
apt install -y bind9 bind9utils bind9-doc dnsutils

# Backup original configuration
echo "Backing up original configuration..."
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.orig 2>/dev/null || true
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.orig 2>/dev/null || true

# Copy configuration files
echo "Installing configuration files..."
cp named.conf.options /etc/bind/named.conf.options
cp named.conf.local /etc/bind/named.conf.local
cp db.site1.lab /etc/bind/db.site1.lab
cp db.192 /etc/bind/db.192
cp db.site2.local /etc/bind/db.site2.local
cp db.internal.cluster /etc/bind/db.internal.cluster

# Set permissions
chown root:bind /etc/bind/db.site1.lab /etc/bind/db.192 /etc/bind/db.site2.local /etc/bind/db.internal.cluster
chmod 640 /etc/bind/db.site1.lab /etc/bind/db.192 /etc/bind/db.site2.local /etc/bind/db.internal.cluster

# Validate configuration
echo "Validating configuration..."
named-checkconf && echo "Main configuration valid"
named-checkzone site1.lab /etc/bind/db.site1.lab && echo "site1.lab zone valid"
named-checkzone 75.168.192.in-addr.arpa /etc/bind/db.192 && echo "Reverse zone valid"
named-checkzone site2.local /etc/bind/db.site2.local && echo "site2.local zone valid"
named-checkzone internal.cluster /etc/bind/db.internal.cluster && echo "internal.cluster zone valid"

# Start Bind9
echo "Starting Bind9..."
systemctl enable bind9
systemctl restart bind9

if systemctl is-active --quiet bind9; then
    echo "Bind9 started successfully"
else
    echo "Error: Bind9 failed to start"
    systemctl status bind9
    exit 1
fi

echo "Setup complete. Test with: bash test-dns.sh"
