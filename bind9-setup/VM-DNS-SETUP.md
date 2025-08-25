# VM-Based DNS Setup Guide

## Overview
This guide explains how to set up Bind9 DNS server in a VM placed in the DMZ network for better security and pfSense integration.

## Architecture Benefits - VM in DMZ

### Security Advantages:
- ✅ **Network Isolation**: DNS VM isolated from main LAN
- ✅ **pfSense Control**: All traffic controlled by firewall rules
- ✅ **DMZ Placement**: Separate network segment for infrastructure services
- ✅ **VM Security**: Snapshot, backup, and restore capabilities
- ✅ **Resource Control**: Dedicated resources, easy scaling

### Network Layout:
```
Internet → pfSense → DMZ (DNS VM) → Internal LAN
                  ↓
                  WAN (Public Services)
```

## Step 1: Clean Up Host Installation

If you already installed Bind9 on the host, clean it up first:

```bash
# Run the cleanup script
chmod +x cleanup-host-bind9.sh
sudo ./cleanup-host-bind9.sh
```

Or manually:
```bash
# Stop and remove Bind9 from host
sudo systemctl stop bind9
sudo systemctl disable bind9
sudo apt remove --purge -y bind9 bind9utils bind9-doc
sudo rm -rf /etc/bind /var/cache/bind /var/lib/bind
```

## Step 2: Create DNS VM in Proxmox

### VM Specifications:
- **CPU**: 1-2 cores
- **RAM**: 1-2 GB
- **Storage**: 8-16 GB
- **OS**: Ubuntu 22.04 LTS or Debian 12
- **Network**: DMZ network bridge

### Proxmox VM Creation:
1. **Log into Proxmox web interface**
2. **Create VM**:
   - **General**: VM ID (e.g., 200), Name: "dns-server"
   - **OS**: Ubuntu/Debian ISO
   - **System**: Default settings
   - **Disks**: 16GB, VirtIO SCSI
   - **CPU**: 2 cores, host CPU type
   - **Memory**: 2048 MB
   - **Network**: Bridge to DMZ network (vmbr1 or similar)

### Network Configuration:
```yaml
# /etc/netplan/01-static-ip.yaml in DNS VM
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:  # or your VM interface name
      dhcp4: no
      addresses:
        - 10.10.10.53/24     # DMZ network IP for DNS
      gateway4: 10.10.10.1   # pfSense DMZ gateway
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]  # Temporary external DNS
```

## Step 3: pfSense DMZ Network Setup

### Create DMZ Network in pfSense:

1. **Interfaces → Assignments**
   - Add DMZ interface (e.g., OPT1)
   - Enable interface
   - Set static IP: `10.10.10.1/24`

2. **Services → DHCP Server → DMZ**
   - Disable DHCP (we'll use static IPs)

3. **Firewall → Rules → DMZ**
   - **Rule 1**: Allow DNS queries from LAN to DMZ DNS
     - Action: Pass
     - Protocol: TCP/UDP
     - Source: LAN net (192.168.75.0/24)
     - Destination: DMZ DNS (10.10.10.53)
     - Port: 53
   
   - **Rule 2**: Allow DNS server to access external DNS
     - Action: Pass
     - Protocol: TCP/UDP
     - Source: DMZ DNS (10.10.10.53)
     - Destination: Any
     - Port: 53

4. **Firewall → Rules → LAN**
   - **Rule**: Allow LAN to DMZ DNS
     - Action: Pass
     - Protocol: TCP/UDP
     - Source: LAN net
     - Destination: Single host (10.10.10.53)
     - Port: 53

## Step 4: Install and Configure Bind9 in VM

### Install Ubuntu/Debian in VM:
```bash
# After OS installation, update system
sudo apt update && sudo apt upgrade -y

# Install Bind9
sudo apt install -y bind9 bind9utils bind9-doc dnsutils

# Add /usr/sbin to PATH
echo 'export PATH=$PATH:/usr/sbin' >> ~/.bashrc
source ~/.bashrc
```

### Configure Static IP:
```bash
# Apply network configuration
sudo netplan apply

# Verify IP
ip addr show
ping 10.10.10.1  # Test gateway
ping 8.8.8.8     # Test external connectivity
```

### Configure Bind9:
Use the same configuration files but update IPs:

#### Update named.conf.options:
```conf
acl "trusted" {
    127.0.0.1;
    ::1;
    192.168.75.0/24;   // Internal LAN
    10.10.10.0/24;     // DMZ network
};

options {
    directory "/var/cache/bind";
    
    forwarders {
        1.1.1.1;
        8.8.8.8;
    };
    
    listen-on port 53 { 127.0.0.1; 10.10.10.53; };  // DMZ IP
    listen-on-v6 { none; };
    
    allow-query { trusted; };
    allow-recursion { trusted; };
    allow-transfer { none; };
    recursion yes;
    
    dnssec-validation auto;
    auth-nxdomain yes;
    minimal-responses yes;
};
```

#### Update zone files:
```dns
# In db.site1.lab - update DNS server IP
ns1             IN      A       10.10.10.53     ; DNS server in DMZ
dns             IN      A       10.10.10.53     ; DNS server alias

# Keep other IPs the same (they're in LAN)
prox1           IN      A       192.168.75.4
prox2           IN      A       192.168.75.5
prox3           IN      A       192.168.75.6
prox4           IN      A       192.168.75.8
pfsense         IN      A       192.168.75.1
```

#### Create reverse zone for DMZ:
```bash
# Add to named.conf.local
zone "10.10.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.10.10.10";
    allow-transfer { none; };
};
```

```dns
# Create /etc/bind/db.10.10.10
$TTL    604800
@       IN      SOA     ns1.site1.lab. admin.site1.lab. (
                              2025080801 ; Serial
                                  604800
                                   86400
                                 2419200
                                  604800
)

@       IN      NS      ns1.site1.lab.

; PTR records for DMZ
1       IN      PTR     pfsense-dmz.site1.lab.
53      IN      PTR     dns.site1.lab.
```

## Step 5: Update pfSense DNS Configuration

### Configure pfSense to use DMZ DNS:

1. **Services → DHCP Server → LAN**
   - **DNS servers**: 
     - Primary: `10.10.10.53` (DMZ DNS)
     - Secondary: `1.1.1.1` (fallback)

2. **System → General Setup**
   - **DNS Server Settings**:
     - DNS Server 1: `10.10.10.53`
     - DNS Server 2: `1.1.1.1`

3. **Services → DNS Resolver**
   - **Outgoing Network Interfaces**: All
   - **Custom Options**: Add if needed:
     ```
     forward-zone:
         name: "site1.lab"
         forward-addr: 10.10.10.53
     ```

## Step 6: Testing the Setup

### Test from DNS VM:
```bash
# Test local resolution
dig @127.0.0.1 prox1.site1.lab A +short
dig @127.0.0.1 dns.site1.lab A +short

# Test external resolution
dig @127.0.0.1 google.com A +short
```

### Test from LAN clients:
```bash
# Test internal resolution
dig @10.10.10.53 prox1.site1.lab A +short
nslookup prox1.site1.lab 10.10.10.53

# Test if clients get DNS from DHCP
cat /etc/resolv.conf
# Should show: nameserver 10.10.10.53
```

### Test pfSense integration:
```bash
# From pfSense shell
nslookup prox1.site1.lab
# Should resolve via DMZ DNS
```

## Step 7: Security and Monitoring

### VM Security:
```bash
# Update VM regularly
sudo apt update && sudo apt upgrade

# Configure firewall on VM
sudo ufw enable
sudo ufw allow 53
sudo ufw allow ssh

# Monitor DNS logs
sudo journalctl -u bind9 -f
```

### pfSense Monitoring:
- **Status → System Logs → Firewall**: Monitor DNS traffic
- **Status → Monitoring**: Track DNS query performance
- **Diagnostics → DNS Lookup**: Test DNS resolution

## Step 8: Backup and Snapshots

### Proxmox Snapshots:
1. **Select DNS VM in Proxmox**
2. **Snapshots → Take Snapshot**
3. **Name**: "dns-config-YYYY-MM-DD"
4. **Include RAM**: No (for config snapshots)

### Configuration Backup:
```bash
# In DNS VM
sudo tar -czvf /root/dns-backup-$(date +%F).tgz /etc/bind
scp /root/dns-backup-*.tgz user@backup-server:/backups/
```

## Advantages of This Architecture

### Security:
- ✅ **Network Segmentation**: DNS isolated in DMZ
- ✅ **Firewall Control**: All traffic filtered by pfSense
- ✅ **VM Isolation**: Contained environment
- ✅ **Easy Recovery**: VM snapshots and backups

### Management:
- ✅ **pfSense Integration**: Native firewall management
- ✅ **Scalability**: Easy to add more DNS VMs
- ✅ **Monitoring**: Centralized logging and monitoring
- ✅ **Updates**: Independent VM updates

### Future Expansion:
- ✅ **HA Setup**: Easy to add secondary DNS VM
- ✅ **Load Balancing**: pfSense can balance between DNS VMs
- ✅ **Service Integration**: Other DMZ services can use same pattern
- ✅ **Kubernetes Ready**: Can integrate with future K8s deployments

This VM-based approach in the DMZ is much more robust and aligns perfectly with your enterprise architecture goals!
