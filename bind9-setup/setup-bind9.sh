#!/bin/bash

# Bind9 DNS Server Setup Script
# Run this on Node 3 (192.168.75.6)

set -e

echo "====================================="
echo "Bind9 DNS Server Setup Script"
echo "====================================="
echo "Setting up internal DNS for site1.lab"
echo "DNS Server IP: 192.168.75.6"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Update system packages
echo "Step 1: Updating system packages..."
apt update && apt upgrade -y

# Install Bind9 and utilities
echo "Step 2: Installing Bind9 and utilities..."
apt install -y bind9 bind9utils bind9-doc dnsutils net-tools

# Backup original configuration files
echo "Step 3: Backing up original configuration files..."
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.orig
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.orig

# Copy configuration files
echo "Step 4: Installing Bind9 configuration files..."

# Copy main configuration files
cp named.conf.options /etc/bind/named.conf.options
cp named.conf.local /etc/bind/named.conf.local

# Copy zone files
cp db.site1.lab /etc/bind/db.site1.lab
cp db.192 /etc/bind/db.192

# Set proper ownership and permissions
echo "Step 5: Setting file permissions..."
chown root:bind /etc/bind/db.site1.lab /etc/bind/db.192
chmod 640 /etc/bind/db.site1.lab /etc/bind/db.192

# Validate configuration
echo "Step 6: Validating Bind9 configuration..."

echo "Checking main configuration..."
if named-checkconf; then
    echo "✓ Main configuration is valid"
else
    echo "✗ Main configuration has errors"
    exit 1
fi

echo "Checking forward zone..."
if named-checkzone site1.lab /etc/bind/db.site1.lab; then
    echo "✓ Forward zone is valid"
else
    echo "✗ Forward zone has errors"
    exit 1
fi

echo "Checking reverse zone..."
if named-checkzone 75.168.192.in-addr.arpa /etc/bind/db.192; then
    echo "✓ Reverse zone is valid"
else
    echo "✗ Reverse zone has errors"
    exit 1
fi

# Setup static IP (optional - comment out if already configured)
echo "Step 7: Setting up static IP (optional)..."
if [ ! -f /etc/netplan/01-static-ip.yaml ]; then
    echo "Installing static IP configuration..."
    cp 01-static-ip.yaml /etc/netplan/01-static-ip.yaml
    echo "Static IP config installed. Apply with: sudo netplan apply"
else
    echo "Static IP config already exists, skipping..."
fi

# Start and enable Bind9
echo "Step 8: Starting and enabling Bind9..."
systemctl enable bind9
systemctl restart bind9

# Check service status
echo "Step 9: Checking Bind9 service status..."
if systemctl is-active --quiet bind9; then
    echo "✓ Bind9 is running successfully"
    systemctl status bind9 --no-pager -l
else
    echo "✗ Bind9 failed to start"
    systemctl status bind9 --no-pager -l
    exit 1
fi

# Install helper scripts
echo "Step 10: Installing helper scripts..."
cp increment-serial.sh /usr/local/bin/increment-bind-serial.sh
chmod +x /usr/local/bin/increment-bind-serial.sh

echo ""
echo "====================================="
echo "Bind9 Setup Complete!"
echo "====================================="
echo ""
echo "DNS Server is now running on: 192.168.75.6"
echo "Internal domain: site1.lab"
echo ""
echo "Next steps:"
echo "1. Test DNS resolution: bash test-dns.sh"
echo "2. Configure pfSense DHCP to use 192.168.75.6 as DNS server"
echo "3. Update client machines to use this DNS server"
echo ""
echo "Useful commands:"
echo "- Check logs: sudo journalctl -u bind9 --since '5 minutes ago'"
echo "- Reload zones: sudo rndc reload"
echo "- Update serial: sudo /usr/local/bin/increment-bind-serial.sh"
echo ""
