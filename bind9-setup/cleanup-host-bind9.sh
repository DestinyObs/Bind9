#!/bin/bash

# Script to completely remove Bind9 from host system
# Run this on Node 3 to clean up before moving to VM approach

echo "====================================="
echo "Bind9 Host Cleanup Script"
echo "====================================="
echo "Removing Bind9 from host system..."
echo "You will deploy Bind9 in a VM instead"
echo ""

# Stop and disable Bind9 service
echo "Step 1: Stopping Bind9 service..."
sudo systemctl stop bind9
sudo systemctl disable bind9
echo "✓ Bind9 service stopped and disabled"

# Remove Bind9 packages
echo ""
echo "Step 2: Removing Bind9 packages..."
sudo apt remove --purge -y bind9 bind9utils bind9-doc bind9-utils dns-root-data dnsutils
sudo apt autoremove -y
echo "✓ Bind9 packages removed"

# Remove configuration files and directories
echo ""
echo "Step 3: Cleaning up configuration files..."
sudo rm -rf /etc/bind
sudo rm -rf /var/cache/bind
sudo rm -rf /var/lib/bind
echo "✓ Configuration directories removed"

# Remove bind user and group (if no other services use them)
echo ""
echo "Step 4: Removing bind user and group..."
if id "bind" &>/dev/null; then
    sudo deluser bind
    sudo delgroup bind
    echo "✓ Bind user and group removed"
else
    echo "ℹ Bind user/group already removed"
fi

# Clean up any remaining systemd files
echo ""
echo "Step 5: Cleaning up systemd files..."
sudo systemctl daemon-reload
sudo systemctl reset-failed
echo "✓ Systemd cleaned up"

# Remove PATH modification from bashrc (optional)
echo ""
echo "Step 6: Cleaning up PATH modification..."
if grep -q "export PATH=\$PATH:/usr/sbin" ~/.bashrc; then
    sed -i '/export PATH=\$PATH:\/usr\/sbin/d' ~/.bashrc
    echo "✓ PATH modification removed from ~/.bashrc"
    echo "ℹ Run 'source ~/.bashrc' or restart terminal to apply"
else
    echo "ℹ No PATH modification found in ~/.bashrc"
fi

# Check if any Bind processes are still running
echo ""
echo "Step 7: Checking for remaining processes..."
if pgrep -x "named" > /dev/null; then
    echo "⚠ Named processes still running, killing them..."
    sudo pkill -f named
    sleep 2
    if pgrep -x "named" > /dev/null; then
        sudo pkill -9 -f named
        echo "✓ Named processes forcefully terminated"
    else
        echo "✓ Named processes terminated"
    fi
else
    echo "✓ No named processes running"
fi

# Verify cleanup
echo ""
echo "Step 8: Verifying cleanup..."
if systemctl list-units --all | grep -q bind9; then
    echo "⚠ Some bind9 systemd units may still exist"
else
    echo "✓ No bind9 systemd units found"
fi

if [ -d /etc/bind ]; then
    echo "⚠ /etc/bind directory still exists"
else
    echo "✓ /etc/bind directory removed"
fi

if command -v named &> /dev/null; then
    echo "⚠ named command still available"
else
    echo "✓ named command no longer available"
fi

echo ""
echo "====================================="
echo "Bind9 Host Cleanup Complete!"
echo "====================================="
echo ""
echo "Host system is now clean. Next steps:"
echo "1. Create a new VM for DNS server"
echo "2. Place VM in DMZ network"
echo "3. Install Bind9 in the VM"
echo "4. Configure pfSense integration"
echo ""
echo "The VM approach provides:"
echo "- Better security isolation"
echo "- Easier pfSense integration"
echo "- DMZ network placement"
echo "- Snapshot/backup capabilities"
echo ""
