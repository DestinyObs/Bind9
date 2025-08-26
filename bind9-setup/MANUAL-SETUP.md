# Bind9 DNS Server - Manual Setup Instructions

## Prerequisites
- Ubuntu/Debian server in DMZ (172.16.25.2)
- Root or sudo access
- Network connectivity to other nodes

## Step-by-Step Manual Setup

### 1. Configure Static IP Address

#### For Ubuntu 20.04+ (Netplan)
```bash
# Create netplan configuration
sudo nano /etc/netplan/01-static-ip.yaml
```

Copy the content from `01-static-ip.yaml` file, then:
```bash
# Apply the configuration
sudo netplan apply

# Verify the IP is set
ip addr show eth0
ip route show
```

#### For older systems (/etc/network/interfaces)
```bash
sudo nano /etc/network/interfaces
```

Add:
```
auto eth0
iface eth0 inet static
    address 172.16.25.2
    netmask 255.255.255.0
    gateway 172.16.25.1
    dns-nameservers 172.16.25.2 1.1.1.1
```

Then restart networking:
```bash
sudo systemctl restart networking
```

### 2. Install Bind9 Packages

```bash
# Update package lists
sudo apt update

# Install Bind9 and utilities
sudo apt install -y bind9 bind9utils bind9-doc dnsutils

# Add /usr/sbin to PATH for named command (Debian/Ubuntu)
echo 'export PATH=$PATH:/usr/sbin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
named -v
# Should show: BIND 9.18.x

# Check service status
sudo systemctl status bind9
# Should show: active (running)
```

**Note for Debian Users**: The installation automatically:
- Creates `bind` user and group
- Enables the service (`named.service`)
- Starts Bind9 in the background
- IPv6 warnings are normal if you don't have IPv6 configured

### 3. Configure Bind9 Main Options

```bash
# Backup original configuration
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.orig

# Edit the main configuration
sudo nano /etc/bind/named.conf.options
```

Replace the content with the content from `named.conf.options` file.

### 4. Configure Local Zones

```bash
# Backup original local configuration
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.orig

# Edit local zones configuration
sudo nano /etc/bind/named.conf.local
```

Replace the content with the content from `named.conf.local` file.

### 5. Create Zone Files

```bash
# Create the main domain zone file
sudo nano /etc/bind/db.cybacad.lab
```

Copy the content from `db.cybacad.lab` file.

```bash
# Create the HQ zone file
sudo nano /etc/bind/db.hq.cybacad.lab
```

Copy the content from `db.hq.cybacad.lab` file.

```bash
# Create the remote site zone file
sudo nano /etc/bind/db.remote.cybacad.lab
```

Copy the content from `db.remote.cybacad.lab` file.

```bash
# Create the services zone file
sudo nano /etc/bind/db.services.cybacad.lab
```

Copy the content from `db.services.cybacad.lab` file.

### 6. Create Reverse Zone File

```bash
# Create the reverse zone file
sudo nano /etc/bind/db.192
```

Copy the content from `db.192` file.

### 7. Set Proper Permissions

```bash
# Set ownership and permissions for zone files
sudo chown root:bind /etc/bind/db.cybacad.lab /etc/bind/db.hq.cybacad.lab /etc/bind/db.remote.cybacad.lab /etc/bind/db.services.cybacad.lab /etc/bind/db.192
sudo chmod 640 /etc/bind/db.cybacad.lab /etc/bind/db.hq.cybacad.lab /etc/bind/db.remote.cybacad.lab /etc/bind/db.services.cybacad.lab /etc/bind/db.192
```

### 8. Validate Configuration

```bash
# Check main configuration syntax
sudo named-checkconf
# Should return no output if OK

# Check main domain zone
sudo named-checkzone cybacad.lab /etc/bind/db.cybacad.lab
# Should show: zone cybacad.lab/IN: loaded serial 2024082601

# Check HQ zone
sudo named-checkzone hq.cybacad.lab /etc/bind/db.hq.cybacad.lab

# Check remote zone
sudo named-checkzone remote.cybacad.lab /etc/bind/db.remote.cybacad.lab

# Check services zone
sudo named-checkzone services.cybacad.lab /etc/bind/db.services.cybacad.lab

# Check reverse zone
sudo named-checkzone 75.168.192.in-addr.arpa /etc/bind/db.192
```

### 9. Start and Enable Bind9 Service

```bash
# Enable Bind9 to start at boot
sudo systemctl enable bind9

# Start/restart Bind9
sudo systemctl restart bind9

# Check service status
sudo systemctl status bind9

# Check logs for any errors
sudo journalctl -u bind9 --since "5 minutes ago"
```

### 10. Test DNS Resolution

#### Test from the DNS server itself:
```bash
# Test main domain
dig @127.0.0.1 ns1.cybacad.lab A +short
# Should return: 172.16.25.2

dig @127.0.0.1 prox1.cybacad.lab A +short
# Should return: 192.168.75.4

# Test HQ services
dig @127.0.0.1 prometheus.hq.cybacad.lab A +short
# Should return: 172.16.10.6

dig @127.0.0.1 grafana.hq.cybacad.lab A +short
# Should return: 172.16.10.7

# Test remote site
dig @127.0.0.1 web.remote.cybacad.lab A +short
# Should return: 212.100.90.102

# Test services
dig @127.0.0.1 dns.services.cybacad.lab A +short
# Should return: 172.16.25.2

# Test reverse lookups
dig @127.0.0.1 -x 192.168.75.4 +short
# Should return: prox1.cybacad.lab.

# Test SOA record
dig @127.0.0.1 cybacad.lab SOA +short

# Test external resolution (via forwarders)
dig @127.0.0.1 google.com A +short
# Should return external IP (proves forwarders work)
```

#### Test from another machine on the network:
```bash
# Test from any other host on 192.168.75.0/24
dig @172.16.25.2 prox1.cybacad.lab A +short
dig @172.16.25.2 prometheus.hq.cybacad.lab A +short
host 192.168.75.8 172.16.25.2
```

### 11. Configure Client Machines

#### Option A: Manual configuration on each client
```bash
# Edit resolv.conf (temporary)
sudo nano /etc/resolv.conf
```

Add:
```
nameserver 172.16.25.2
nameserver 1.1.1.1
search cybacad.lab
```

#### Option B: Configure pfSense DHCP (recommended)
1. Log into pfSense web interface
2. Go to **Services → DHCP Server → LAN**
3. Set **DNS servers**: Primary = `172.16.25.2`, Secondary = `1.1.1.1`
4. Set **Domain name**: `cybacad.lab`
5. Save and Apply Changes

### 12. Firewall Configuration

Ensure pfSense allows DNS traffic:
1. Go to **Firewall → Rules → LAN**
2. Verify there's a rule allowing traffic to port 53 (DNS)
3. If not, add a rule:
   - Action: Pass
   - Protocol: UDP/TCP
   - Source: LAN net
   - Destination: Single host or alias = 172.16.25.2
   - Port: 53

## Maintenance Tasks

### Adding New DNS Records

1. Edit the zone file:
```bash
sudo nano /etc/bind/db.cybacad.lab
# or any of the other zone files as needed
```

2. Add your new records (A, CNAME, etc.)

3. Increment the serial number:
```bash
# Use the helper script
sudo /usr/local/bin/increment-bind-serial.sh

# Or manually increment and reload
sudo rndc reload cybacad.lab
```

### Monitoring and Troubleshooting

```bash
# Check service status
sudo systemctl status bind9

# View recent logs
sudo journalctl -u bind9 --since "1 hour ago"

# Check configuration
sudo named-checkconf

# Monitor DNS queries (for debugging)
sudo tcpdump -i any port 53

# Check which DNS server clients are using
systemd-resolve --status
# or
cat /etc/resolv.conf
```

### Common Installation Issues (Debian/Ubuntu)

#### Issue: IPv6 "network unreachable" warnings
**Status**: Normal - These warnings are harmless if you don't have IPv6
**Solution**: Can be ignored, or disable IPv6 in named.conf.options:
```bash
listen-on-v6 { none; };
```

#### Issue: "named: command not found"
**Solution**: Add /usr/sbin to PATH:
```bash
echo 'export PATH=$PATH:/usr/sbin' >> ~/.bashrc
source ~/.bashrc
```

#### Issue: Permission denied on zone files
**Solution**: Check ownership:
```bash
sudo chown root:bind /etc/bind/db.*
sudo chmod 640 /etc/bind/db.*
```

### Backup and Recovery

```bash
# Create backup
sudo tar -czvf /root/bind-backup-$(date +%F).tgz /etc/bind

# Restore from backup
sudo tar -xzvf /root/bind-backup-YYYY-MM-DD.tgz -C /
sudo systemctl restart bind9
```

## Security Considerations

1. **Access Control**: The configuration restricts queries to the `trusted` ACL (192.168.75.0/24)
2. **Zone Transfers**: Disabled by default (`allow-transfer { none; }`)
3. **Recursion**: Limited to trusted networks only
4. **Minimal Responses**: Enabled to reduce information leakage

## Next Steps

After completing the DNS setup:

1. **Test thoroughly** with the provided test script
2. **Configure all client machines** to use this DNS server
3. **Update pfSense DHCP** to distribute the DNS server automatically
4. **Add monitoring** to ensure DNS service availability
5. **Set up log rotation** for DNS logs
6. **Consider secondary DNS** for high availability

## Common Issues and Solutions

### Issue: Bind9 fails to start
**Solution**: Check logs and configuration:
```bash
sudo journalctl -u bind9 --since "5 minutes ago"
sudo named-checkconf
```

### Issue: DNS queries not working from clients
**Solutions**:
1. Check firewall rules allow port 53
2. Verify client DNS configuration
3. Test with `dig @172.16.25.2 hostname.cybacad.lab`

### Issue: External domains not resolving
**Solution**: Check forwarders configuration in `named.conf.options`

### Issue: Permission denied errors
**Solution**: Check file ownership and permissions:
```bash
sudo chown root:bind /etc/bind/db.*
sudo chmod 640 /etc/bind/db.*
```
