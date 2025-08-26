# Bind9 DNS Server Setup

## Network Configuration
- DNS Server: 172.16.25.2 (DMZ)
- Internal Domains: site1.lab, site2.local, internal.cluster
- LAN Network: 192.168.75.0/24
- DMZ Network: 172.16.25.0/24

## DNS Zones
- **site1.lab** - Primary internal services
- **site2.local** - External/remote services (212.100.90.102)
- **internal.cluster** - Cross-service discovery

## Essential Files
- `named.conf.options` - Main configuration
- `named.conf.local` - Zone definitions
- `db.site1.lab` - Primary forward zone
- `db.site2.local` - Site 2 zone
- `db.internal.cluster` - Internal cluster zone
- `db.192` - Reverse zone
- `setup-bind9.sh` - Installation script
- `test-dns.sh` - Testing script

## Current Service Records
- prometheus.site1.lab -> 172.16.10.6
- grafana.site1.lab -> 172.16.10.7
- web.site2.local -> 212.100.90.102 (ready for deployment)
- grafana.site1.local -> 172.16.10.7

## Deployment
1. Copy files to DNS server: `scp -r * user@172.16.25.2:/tmp/`
2. Run setup: `sudo bash setup-bind9.sh`
3. Test functionality: `bash test-dns.sh`
