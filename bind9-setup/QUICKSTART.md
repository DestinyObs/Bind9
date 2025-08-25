# Quick Start Guide - Bind9 DNS Setup

## Prerequisites
- Node 3 (192.168.75.6) accessible via SSH
- Root/sudo access on the server
- All files downloaded to the DNS server

## Option 1: Automated Setup (Recommended)

### Step 1: Copy Files to Server
```bash
# On your local machine, copy all files to the DNS server
scp -r bind9-setup/ user@192.168.75.6:~/

# SSH to the server
ssh user@192.168.75.6
```

### Step 2: Run Automated Setup
```bash
# Navigate to the setup directory
cd ~/bind9-setup

# Make scripts executable
chmod +x setup-bind9.sh test-dns.sh increment-serial.sh

# Run the setup script
sudo ./setup-bind9.sh
```

### Step 3: Test the Installation
```bash
# Run the test script
./test-dns.sh
```

### Step 4: Apply Static IP (if needed)
```bash
# Apply the static IP configuration
sudo netplan apply

# Verify the IP is set correctly
ip addr show
```

## Option 2: Manual Setup

Follow the detailed instructions in `MANUAL-SETUP.md` for step-by-step manual installation.

## Post-Installation Tasks

### 1. Configure pfSense
- Follow instructions in `PFSENSE-INTEGRATION.md`
- Set DHCP to distribute 192.168.75.6 as DNS server

### 2. Test from Client Machines
```bash
# Test internal resolution
ping prox1.site1.lab
nslookup grafana.site1.lab

# Test external resolution
ping google.com
```

### 3. Monitor the Service
```bash
# Check service status
sudo systemctl status bind9

# View logs
sudo journalctl -u bind9 --since "10 minutes ago"

# Monitor DNS queries
sudo tail -f /var/log/syslog | grep named
```

## Daily Operations

### Adding New DNS Records
1. Edit `/etc/bind/db.site1.lab`
2. Add your A, CNAME, or other records
3. Run: `sudo /usr/local/bin/increment-bind-serial.sh`

### Backup Configuration
```bash
sudo tar -czvf ~/dns-backup-$(date +%Y%m%d).tgz /etc/bind
```

### Updating Records Example
```bash
# Edit zone file
sudo nano /etc/bind/db.site1.lab

# Add new record:
# newserver    IN    A    192.168.75.10

# Increment serial and reload
sudo /usr/local/bin/increment-bind-serial.sh
```

## Troubleshooting

### Service Issues
```bash
# Check if Bind9 is running
sudo systemctl status bind9

# Restart if needed
sudo systemctl restart bind9

# Check configuration syntax
sudo named-checkconf
```

### DNS Resolution Issues
```bash
# Test DNS server directly
dig @192.168.75.6 prox1.site1.lab

# Check if server is listening
sudo netstat -tulpn | grep :53

# Check firewall
sudo ufw status
```

### Client Configuration Issues
```bash
# Check what DNS server client is using
cat /etc/resolv.conf

# Force DHCP renewal
sudo dhclient -r && sudo dhclient
```

## Support and Documentation

- **Detailed Manual Setup**: See `MANUAL-SETUP.md`
- **pfSense Integration**: See `PFSENSE-INTEGRATION.md`
- **Configuration Files**: All files are documented with comments
- **Log Files**: `/var/log/syslog` contains Bind9 logs

## Success Indicators

✅ **Setup is successful when:**
- `sudo systemctl status bind9` shows active (running)
- `./test-dns.sh` shows all tests passing
- Clients can resolve `prox1.site1.lab` to `192.168.75.4`
- External sites like `google.com` still resolve
- pfSense DHCP distributes the DNS server to clients

## Contact Information

For issues with this setup, check:
1. Service logs: `sudo journalctl -u bind9`
2. Configuration validation: `sudo named-checkconf`
3. Network connectivity: `ping 192.168.75.6`
4. Firewall rules in pfSense
