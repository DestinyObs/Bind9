# pfSense DNS Integration Guide

## Overview
This guide explains how to integrate your new Bind9 DNS server with pfSense to automatically distribute DNS settings to all clients via DHCP.

## pfSense Configuration Steps

### 1. Configure DHCP Server to Use Bind9

1. **Log into pfSense Web Interface**
   - Open web browser and navigate to your pfSense IP (typically 192.168.75.1)
   - Login with admin credentials

2. **Navigate to DHCP Settings**
   - Go to **Services → DHCP Server**
   - Click on the **LAN** tab

3. **Configure DNS Servers**
   - In the **DNS servers** section:
     - **Primary DNS**: `192.168.75.6` (your Bind9 server)
     - **Secondary DNS**: `1.1.1.1` (Cloudflare fallback)
   - In the **Domain name** field: `site1.lab`
   - In the **Domain search list**: `site1.lab`

4. **Save and Apply**
   - Click **Save**
   - The changes will be applied immediately

### 2. Configure DNS Resolver (Optional)

If you want pfSense to also use your internal DNS:

1. **Navigate to DNS Resolver**
   - Go to **Services → DNS Resolver**

2. **Configure General Settings**
   - **Enable DNS Resolver**: Checked
   - **Listen Port**: 53
   - **Network Interfaces**: LAN

3. **Advanced Settings**
   - **DNS Query Forwarding**: Enable
   - **Forwarding Mode**: Enabled
   - Add forwarder: `192.168.75.6` (your Bind9 server)

4. **Save and Apply**

### 3. Firewall Rules Verification

Ensure DNS traffic is allowed:

1. **Navigate to Firewall Rules**
   - Go to **Firewall → Rules → LAN**

2. **Check for DNS Rule**
   - Look for a rule allowing traffic to port 53
   - If not present, add one:
     - **Action**: Pass
     - **Interface**: LAN
     - **Protocol**: TCP/UDP
     - **Source**: LAN net
     - **Destination**: Single host → `192.168.75.6`
     - **Destination Port**: 53 (DNS)
     - **Description**: Allow DNS queries to internal DNS server

3. **Apply Changes**

## Client Configuration

### Automatic Configuration (DHCP)

Once pfSense DHCP is configured, clients will automatically receive the DNS settings when they:
- Renew their DHCP lease
- Reconnect to the network
- Restart their network interface

To force immediate update on clients:

#### Linux/Ubuntu:
```bash
sudo dhclient -r && sudo dhclient
# Or
sudo systemctl restart networking
```

#### Windows:
```cmd
ipconfig /release
ipconfig /renew
```

#### macOS:
```bash
sudo dscacheutil -flushcache
```

### Manual Configuration (if needed)

#### Ubuntu/Linux:
```bash
# Edit netplan (Ubuntu 20.04+)
sudo nano /etc/netplan/01-netcfg.yaml

# Add under your ethernet interface:
nameservers:
  addresses: [192.168.75.6, 1.1.1.1]
  search: [site1.lab]

# Apply changes
sudo netplan apply
```

#### Windows:
1. Open Network Settings
2. Change adapter options
3. Right-click your network connection → Properties
4. Select "Internet Protocol Version 4 (TCP/IPv4)" → Properties
5. Select "Use the following DNS server addresses"
6. Preferred: `192.168.75.6`
7. Alternate: `1.1.1.1`

## Testing Integration

### 1. Verify DHCP is distributing DNS settings

From a client machine:
```bash
# Linux
cat /etc/resolv.conf
# Should show: nameserver 192.168.75.6

# Windows
ipconfig /all
# Should show DNS servers including 192.168.75.6
```

### 2. Test internal name resolution

From any client:
```bash
# Test internal hosts
ping prox1.site1.lab
ping grafana.site1.lab
ping mssql.site1.lab

# Test external resolution
ping google.com
```

### 3. Use nslookup/dig for detailed testing

```bash
# Test internal resolution
nslookup prox1.site1.lab
dig prox1.site1.lab

# Test reverse resolution
nslookup 192.168.75.4
dig -x 192.168.75.4

# Test external resolution
nslookup google.com
```

## Advanced pfSense DNS Configuration

### DNS Forwarder Alternative

If you prefer using DNS Forwarder instead of DNS Resolver:

1. **Disable DNS Resolver**
   - Services → DNS Resolver → Disable

2. **Enable DNS Forwarder**
   - Services → DNS Forwarder → Enable
   - Configure to forward to `192.168.75.6`

### Custom DNS Overrides

To add additional local DNS entries in pfSense:

1. **Navigate to DNS Resolver/Forwarder**
2. **Host Overrides** section
3. **Add entries** for any additional hosts
4. **Save and Apply**

### DNS over HTTPS/TLS (Optional)

For enhanced security, you can configure DNS over HTTPS:

1. **Services → DNS Resolver**
2. **Advanced Settings**
3. **Enable DNS over TLS/HTTPS**
4. **Configure upstream servers** supporting DoH/DoT

## Monitoring and Troubleshooting

### pfSense DNS Logs

1. **View DNS logs**:
   - Status → System Logs → System → DNS Resolver/Forwarder

2. **Monitor DHCP leases**:
   - Status → DHCP Leases
   - Verify clients are receiving correct DNS settings

### Common Issues

#### Issue: Clients not receiving DNS settings
**Solutions**:
1. Check DHCP server is enabled and running
2. Verify clients are getting DHCP leases
3. Force DHCP renewal on clients
4. Check firewall rules aren't blocking DHCP

#### Issue: DNS resolution not working
**Solutions**:
1. Test DNS server directly: `dig @192.168.75.6 site1.lab`
2. Check pfSense can reach DNS server: `ping 192.168.75.6`
3. Verify firewall rules allow DNS traffic
4. Check DNS server logs on Bind9 server

#### Issue: Some domains don't resolve
**Solutions**:
1. Check if it's internal vs external domain issue
2. Verify forwarders are configured correctly
3. Test external resolution from DNS server directly

## Security Considerations

1. **Access Control**: Ensure only LAN clients can query the DNS server
2. **Monitoring**: Monitor DNS query logs for unusual activity
3. **Updates**: Keep both pfSense and Bind9 updated
4. **Backup**: Regular backup of pfSense configuration
5. **Redundancy**: Consider secondary DNS server for high availability

## Next Steps

After successful integration:

1. **Monitor performance** and query patterns
2. **Set up alerting** for DNS service failures
3. **Document** your DNS infrastructure
4. **Train team members** on DNS management
5. **Plan for** disaster recovery scenarios

## Backup pfSense Configuration

Don't forget to backup your pfSense configuration:

1. **Diagnostics → Backup & Restore**
2. **Download configuration** as XML
3. **Store securely** with your other backups
