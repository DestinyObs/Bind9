# Bind9 DNS Server Setup Guide

## Overview
This guide sets up Bind9 DNS server on Node 3 (192.168.75.6) for internal name resolution in your Proxmox cluster.

## Network Layout
- **192.168.75.4** - Server 1 (Node1) - Wazuh/pfSense VMs
- **192.168.75.5** - Server 2 (Node2) - Prometheus/Grafana
- **192.168.75.6** - Server 3 (Node3) - DNS server (Bind9) + CI/CD
- **192.168.75.8** - Server 4 (Node4) - MSSQL/Backup

## Domain Structure
- **Internal Zone**: `site1.lab`
- **DNS Server**: `ns1.site1.lab` (192.168.75.6)
- **Reverse Zone**: `75.168.192.in-addr.arpa` for 192.168.75.0/24

## Files Included
1. `01-static-ip.yaml` - Netplan configuration for static IP
2. `named.conf.options` - Bind9 global options
3. `named.conf.local` - Zone declarations
4. `db.site1.lab` - Forward zone file
5. `db.192` - Reverse zone file
6. `setup-bind9.sh` - Complete installation script
7. `test-dns.sh` - DNS testing script
8. `increment-serial.sh` - Zone serial increment helper

## Quick Setup
1. Copy all files to your DNS server (192.168.75.6)
2. Run: `sudo bash setup-bind9.sh`
3. Test with: `bash test-dns.sh`

## Manual Setup Steps
See `MANUAL-SETUP.md` for detailed step-by-step instructions.
