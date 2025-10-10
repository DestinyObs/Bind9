
# Bind9 DNS Infrastructure: Professional Reference & Course

## Table of Contents
1. [Introduction: What is Bind9?](#introduction)
2. [DNS Concepts: Authoritative, Recursive, Forward/Reverse](#dns-concepts)
3. [Project Goals & Design Philosophy](#project-goals)
4. [Network & Zone Architecture](#network-architecture)
5. [File-by-File Breakdown](#file-breakdown)
6. [Zone File & Config Syntax Explained](#syntax-explained)
7. [Deployment & Validation](#deployment)
8. [Troubleshooting & Best Practices](#troubleshooting)
9. [Further Reading](#further-reading)

---

## 1. Introduction: What is Bind9?
Bind9 is the de facto standard open-source DNS server for Unix-like systems. It provides authoritative and recursive DNS services, supporting all modern DNS features, security extensions (DNSSEC), and flexible configuration for enterprise environments.

**Why DNS?** DNS (Domain Name System) translates human-readable names (like `server.lab`) to IP addresses. It is foundational to all networked systems.

**Why Bind9?** Bind9 is trusted for its reliability, configurability, and industry adoption. It is used by ISPs, enterprises, and root DNS operators.

---

## 2. DNS Concepts: Authoritative, Recursive, Forward/Reverse

**Authoritative DNS**: Answers queries about domains it manages (e.g., `cybacad.lab`).

**Recursive DNS**: Resolves queries for any domain by querying other DNS servers on behalf of the client.

**Forward Zone**: Maps names to IPs (A, AAAA records). Example: `server.lab` → `192.168.1.10`.

**Reverse Zone**: Maps IPs to names (PTR records). Example: `192.168.1.10` → `server.lab`.

**Zone File**: Text file containing all DNS records for a domain or subnet.

**SOA Record**: Start of Authority. Defines the primary server, admin contact, and timing parameters for the zone.

---

## 3. Project Goals & Design Philosophy

**Purpose:**
- Provide a robust, secure, and fully documented DNS infrastructure for a lab/enterprise environment.
- Enable easy onboarding for new admins: every file, directive, and record is explained.
- Support both forward and reverse DNS for all critical subnets and services.

**Design Principles:**
- Explicitness: No magic, no unexplained settings. Every line is commented.
- Security: Only trusted subnets can query or recurse. Zone transfers are disabled.
- Maintainability: All files are modular, with clear separation of concerns.
- Educational Value: This repository is a reference for learning and future audits.

---

## 4. Network & Zone Architecture

**Core Networks:**
- DMZ: `172.16.40.0/24` (DNS server: `172.16.40.2`)
- Proxmox: `192.168.3.0/24`
- Management: `192.168.32.0/24`
- Monitoring: `10.0.5.0/24`
- Security: `40.10.10.0/24`

**Zones:**
- `cybacad.lab` (main forward zone)
- `hq.cybacad.lab`, `remote.cybacad.lab`, `services.cybacad.lab` (subdomains)
- Reverse zones for each subnet (e.g., `3.168.192.in-addr.arpa`)

**Service Records:**
| Hostname                  | IP Address      | Purpose                        |
|---------------------------|-----------------|---------------------------------|
| prox1.cybacad.lab         | 192.168.3.8     | Proxmox node 1                  |
| prox2.cybacad.lab         | 192.168.3.9     | Proxmox node 2                  |
| pfsense.cybacad.lab       | 192.168.32.1    | Firewall/gateway                |
| windows.cybacad.lab       | 192.168.32.2    | Windows server                  |
| wazuh.cybacad.lab         | 40.10.10.10     | Security monitoring             |
| nodeexp1.cybacad.lab      | 10.0.5.2        | Monitoring exporter             |
| nodeexp2.cybacad.lab      | 10.0.5.3        | Monitoring exporter             |
| prometheus.cybacad.lab    | 10.0.5.4        | Monitoring                      |
| grafana.cybacad.lab       | 10.0.5.5        | Dashboards                      |
| pulse.cybacad.lab         | 10.0.5.8        | Pulse service                   |
| ubuntumonitoring.cybacad.lab | 10.0.5.7     | Monitoring node                 |
| cksm1.cybacad.lab         | 192.168.32.8    | Kubernetes master 1             |
| cksm2.cybacad.lab         | 192.168.32.9    | Kubernetes master 2             |
| cksw1.cybacad.lab         | 192.168.32.10   | Kubernetes worker 1             |
| cksw2.cybacad.lab         | 192.168.32.3    | Kubernetes worker 2             |
| cksw3.cybacad.lab         | 192.168.32.6    | Kubernetes worker 3             |
| cksw4.cybacad.lab         | 192.168.32.7    | Kubernetes worker 4             |

---

## 5. File-by-File Breakdown

### `named.conf.options`
Global Bind9 options. Sets ACLs, recursion, forwarders, and security settings. Every directive is commented in the file.

### `named.conf.local`
Defines all authoritative zones (forward and reverse). Each `zone` block specifies the type, file, and transfer policy.

### `db.cybacad.lab`, `db.hq.cybacad.lab`, `db.remote.cybacad.lab`, `db.services.cybacad.lab`
Forward zone files. Contain A, CNAME, and SOA records for each domain/subdomain. Each record is explained in-line.

### `db.192`, `db.192.168.3`, `db.192.168.32`, `db.10.0.5`, `db.40.10.10`
Reverse zone files. Map IP addresses to hostnames using PTR records. Each record is explained in-line.

### `deploy_bind9.sh`
Automates deployment: copies configs, sets permissions, validates syntax, reloads Bind9, and tests records. See script for detailed comments.

---

## 6. Zone File & Config Syntax Explained

**Zone File Example:**
```zone
$TTL    604800                  ; Default TTL for all records (in seconds)
@       IN      SOA     ns1.cybacad.lab. admin.cybacad.lab. (
						2024060201      ; Serial number (increment on every change)
						604800          ; Refresh interval (how often secondaries check for updates)
						86400           ; Retry interval (if refresh fails)
						2419200         ; Expire (when secondaries consider data stale)
						604800 )        ; Negative Cache TTL (how long to cache NXDOMAIN)
@       IN      NS      ns1.cybacad.lab.        ; Name server for this zone
hostname IN      A       192.168.3.8            ; Maps hostname to IP
```

**Key Directives:**
- `$TTL`: Default time-to-live for all records (in seconds).
- `@`: Represents the current zone origin (the domain itself).
- `IN`: Internet class (almost always IN).
- `SOA`: Start of Authority. Must be present. Contains primary NS, admin email (with `.` for `@`), and timing values.
- `NS`: Name server for the zone.
- `A`: Maps a name to an IPv4 address.
- `PTR`: Maps an IP to a name (reverse lookup).
- `CNAME`: Alias for another name.

**Config File Example:**
```conf
zone "cybacad.lab" {
	type master;                    // This server is the primary (master) for this zone
	file "/etc/bind/db.cybacad.lab"; // Path to the zone file
	allow-transfer { none; };       // Disable zone transfers for security
};
```

**Key Config Directives:**
- `zone`: Declares a DNS zone.
- `type master`: This server is authoritative for the zone.
- `file`: Path to the zone file.
- `allow-transfer { none; }`: Disables zone transfers (AXFR/IXFR).

---

## 7. Deployment & Validation

**Manual Deployment:**
1. Copy all files to the DNS server (e.g., `scp -r * user@192.168.3.9:/tmp/`).
2. Place configs in `/etc/bind/`.
3. Check syntax: `sudo named-checkconf` and `sudo named-checkzone <zone> <file>`.
4. Restart Bind9: `sudo systemctl restart named`.
5. Test with `dig` or `nslookup` from trusted clients.

**Automated Deployment:**
Use `deploy_bind9.sh` to automate all steps above, including syntax checks and service reloads. The script is fully commented for clarity.

---

## 8. Troubleshooting & Best Practices

- Always increment the SOA serial number after any change to a zone file.
- Use `named-checkconf` and `named-checkzone` to validate before restarting Bind9.
- Restrict queries and recursion to trusted subnets only.
- Never allow zone transfers unless required and secured.
- Document every change and keep backups of all config and zone files.
- Use `dig` to test both A and PTR records from multiple clients.

---

## 9. Further Reading

- [Bind9 Administrator Reference Manual](https://bind9.readthedocs.io/en/latest/)
- [DNS RFCs: 1034, 1035](https://datatracker.ietf.org/doc/html/rfc1035)
- [ISC Knowledge Base](https://kb.isc.org/)

---

**This repository is designed to be a gold-standard reference for Bind9 DNS infrastructure. Every file is maximally explicit, with comments and documentation to support both learning and production use.**