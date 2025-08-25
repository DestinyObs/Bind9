# Bind9 DNS Server Setup

## Network Configuration
- DNS Server: 172.16.25.2 (DMZ)
- Internal Domain: site1.lab
- LAN Network: 192.168.75.0/24
- DMZ Network: 172.16.25.0/24

## Essential Files
- `named.conf.options` - Main configuration
- `named.conf.local` - Zone definitions
- `db.site1.lab` - Forward zone
- `db.192` - Reverse zone
- `setup-bind9.sh` - Installation script
- `test-dns.sh` - Testing script

## Deployment
1. Copy files to DNS server: `scp -r * user@172.16.25.2:/tmp/`
2. Run setup: `sudo bash setup-bind9.sh`
3. Test functionality: `bash test-dns.sh`
