sudo rm -f /etc/bind/db.site1.lab
# Bind9 DNS Server Setup

## Network Configuration
- DNS Server: 192.168.3.9 (Node 2, DMZ)
- Internal Domain: cybacad.lab
- Proxmox Nodes: 192.168.3.8, 192.168.3.9
- Management: 192.168.32.0/24
- Monitoring: 10.0.5.0/24

## DNS Zones
- **cybacad.lab** - All internal services and nodes

## Essential Files
- `named.conf.options` - Main configuration
- `named.conf.local` - Zone definitions
- `db.cybacad.lab` - Forward zone
- `db.192` - Reverse zone
- `setup-bind9.sh` - Installation script
- `test-dns.sh` - Testing script

## Current Service Records
- prox1.cybacad.lab -> 192.168.3.8
- prox2.cybacad.lab -> 192.168.3.9
- pfsense.cybacad.lab -> 192.168.32.1
- windows.cybacad.lab -> 192.168.32.2
- wazuh.cybacad.lab -> 40.10.10.10
- nodeexp1.cybacad.lab -> 10.0.5.2
- nodeexp2.cybacad.lab -> 10.0.5.3
- prometheus.cybacad.lab -> 10.0.5.4
- grafana.cybacad.lab -> 10.0.5.5
- pulse.cybacad.lab -> 10.0.5.8
- ubuntumonitoring.cybacad.lab -> 10.0.5.7

## Deployment
1. Copy files to DNS server: `scp -r * user@192.168.3.9:/tmp/`
2. Run setup: `sudo bash setup-bind9.sh`
3. Test functionality: `bash test-dns.sh`