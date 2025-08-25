# Bind9 DNS Deployment Guide

## Quick Deployment
1. Copy files to DNS server: `scp -r * user@172.16.25.2:/tmp/`
2. SSH to server: `ssh user@172.16.25.2`
3. Run setup: `sudo bash /tmp/setup-bind9.sh`
4. Test: `bash /tmp/test-dns.sh`

## Network Details
- DNS Server: 172.16.25.2 (DMZ)
- Internal Domain: site1.lab
- Serves LAN: 192.168.75.0/24

## Configuration Files
- `named.conf.options` - Main configuration with ACLs
- `named.conf.local` - Zone definitions
- `db.site1.lab` - Forward zone records
- `db.192` - Reverse zone records
- `01-static-ip.yaml` - Network configuration

## Post-Deployment
1. Configure pfSense DHCP to use 172.16.25.2 as DNS
2. Add firewall rules for DNS traffic (port 53)
3. Test from LAN clients

## Maintenance
- Update zones: Edit zone files, run `sudo increment-serial.sh`
- Check logs: `sudo journalctl -u bind9`
- Reload config: `sudo rndc reload`
