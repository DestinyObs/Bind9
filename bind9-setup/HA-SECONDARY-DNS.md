# Bind9 High Availability - Secondary DNS Setup

## Overview
This guide shows how to add a secondary (slave) DNS server for high availability.

## Architecture
- **Primary DNS**: 192.168.75.6 (Node 3) - Current setup
- **Secondary DNS**: 192.168.75.X (Choose another node or VM)

## Step 1: Choose Secondary DNS IP
Select an IP for your secondary DNS server:
- Option A: 192.168.75.4 (Node 1) - if not running critical services
- Option B: 192.168.75.5 (Node 2) - if not running critical services  
- Option C: Create a dedicated VM on any node

## Step 2: Update Primary DNS (192.168.75.6)

### 2.1 Update named.conf.options
```bash
sudo nano /etc/bind/named.conf.options
```

Add secondary DNS IP to trusted ACL:
```conf
acl "trusted" {
    127.0.0.1;
    ::1;
    192.168.75.0/24;   // internal LAN
};

acl "slaves" {
    192.168.75.X;      // Replace X with your secondary DNS IP
};
```

### 2.2 Update named.conf.local
```bash
sudo nano /etc/bind/named.conf.local
```

Update zone configurations:
```conf
zone "site1.lab" {
    type master;
    file "/etc/bind/db.site1.lab";
    allow-transfer { slaves; };  // Allow zone transfer to slaves
    also-notify { 192.168.75.X; };  // Notify slaves of updates
};

zone "75.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192";
    allow-transfer { slaves; };
    also-notify { 192.168.75.X; };
};
```

### 2.3 Reload Primary DNS
```bash
sudo named-checkconf
sudo systemctl reload bind9
```

## Step 3: Setup Secondary DNS Server

### 3.1 Install Bind9 on Secondary
```bash
# On the secondary server (192.168.75.X)
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc

# Set static IP for secondary DNS
sudo nano /etc/netplan/01-static-ip.yaml
```

### 3.2 Configure Secondary named.conf.options
```conf
acl "trusted" {
    127.0.0.1;
    ::1;
    192.168.75.0/24;
};

options {
    directory "/var/cache/bind";
    
    forwarders {
        1.1.1.1;
        8.8.8.8;
    };
    
    listen-on port 53 { 127.0.0.1; 192.168.75.X; };  // Secondary IP
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

### 3.3 Configure Secondary named.conf.local
```conf
zone "site1.lab" {
    type slave;
    file "/var/lib/bind/db.site1.lab";  // Slave zone files go in /var/lib/bind
    masters { 192.168.75.6; };          // Primary DNS IP
};

zone "75.168.192.in-addr.arpa" {
    type slave;
    file "/var/lib/bind/db.192";
    masters { 192.168.75.6; };
};
```

### 3.4 Start Secondary DNS
```bash
sudo named-checkconf
sudo systemctl enable bind9
sudo systemctl start bind9
sudo systemctl status bind9
```

## Step 4: Update pfSense DHCP

Update DHCP to provide both DNS servers:
1. **Services → DHCP Server → LAN**
2. **DNS servers**: 
   - Primary: `192.168.75.6`
   - Secondary: `192.168.75.X`

## Step 5: Test HA Setup

### Test Zone Transfer
```bash
# On secondary server, check if zones transferred
sudo ls -la /var/lib/bind/
# Should see db.site1.lab and db.192

# Test zone data
dig @192.168.75.X prox1.site1.lab A +short
# Should return same result as primary
```

### Test Failover
```bash
# Stop primary DNS
sudo systemctl stop bind9  # On primary (192.168.75.6)

# Test resolution from client
dig @192.168.75.X prox1.site1.lab A +short
# Should still work via secondary
```

## Maintenance with HA

### Adding Records
1. **Always edit PRIMARY DNS only** (192.168.75.6)
2. Use increment-serial.sh script
3. Secondary will automatically sync via zone transfer

### Monitoring Both Servers
```bash
# Check both DNS servers
for dns in 192.168.75.6 192.168.75.X; do
    echo "Testing $dns:"
    dig @$dns prox1.site1.lab A +short
done
```

## Kubernetes/ArgoCD Considerations

### Future Integration Options:
1. **External DNS Controller**: Updates Bind9 zones automatically from K8s services
2. **CoreDNS Integration**: Use Bind9 for infrastructure, CoreDNS for cluster-internal
3. **Hybrid Approach**: Bind9 for static infrastructure, dynamic updates for K8s services

### Example External DNS Integration:
```yaml
# external-dns configmap for future K8s deployment
apiVersion: v1
kind: ConfigMap
metadata:
  name: external-dns-config
data:
  bind9-server: "192.168.75.6"
  bind9-zone: "site1.lab"
  # External DNS can update Bind9 via dynamic DNS updates
```

## Security Best Practices

### Network Security
- ✅ DNS servers only accessible from internal network
- ✅ No WAN exposure of DNS service
- ✅ Zone transfers restricted to authorized slaves only
- ✅ Queries restricted to trusted networks

### Monitoring
```bash
# Monitor zone transfers
sudo tail -f /var/log/syslog | grep named

# Monitor DNS queries
sudo tcpdump -i any port 53

# Check slave synchronization
dig @192.168.75.X site1.lab SOA
dig @192.168.75.6 site1.lab SOA
# Serial numbers should match
```

## Integration with Project Architecture

This HA DNS setup perfectly supports your project goals:

### Site 1 (Internal)
- Primary DNS: Node 3 (192.168.75.6)
- Secondary DNS: Node 1/2/4 (your choice)
- All internal services resolve properly
- Automatic failover capability

### Site 2 (Public)
- Uses Site 1 DNS for internal communication
- Public DNS handled by registrar/external provider
- HAProxy in DMZ handles public web traffic
- No internal DNS exposure to internet

### Future Services
- Easy to add new service records
- Automatic propagation to secondary DNS
- Ready for Kubernetes service discovery
- Supports dynamic DNS updates if needed
