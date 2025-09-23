---

## 4. Create Zone Files (Manual Copy-Paste)

For each of the following, open the file with your editor (e.g. `sudo nano /etc/bind/db.cybacad.lab`), erase any existing content, and paste exactly what is shown.

### a) `/etc/bind/db.cybacad.lab`
```zone
$TTL    604800
@       IN      SOA     ns1.cybacad.lab. admin.cybacad.lab. (
                                                2024060201      ; Serial
                                                604800          ; Refresh
                                                86400           ; Retry
                                                2419200         ; Expire
                                                604800 )        ; Negative Cache TTL

; Name servers
@       IN      NS      ns1.cybacad.lab.

; Main DNS server (static IP)
ns1     IN      A       172.16.40.3

; Proxmox nodes
prox1   IN      A       192.168.3.8
prox2   IN      A       192.168.3.9

; Core infrastructure
pfsense IN      A       192.168.32.1
windows IN      A       192.168.32.2
wazuh   IN      A       40.10.10.10
nodeexp1 IN     A       10.0.5.2
nodeexp2 IN     A       10.0.5.3
prometheus IN   A       10.0.5.4
grafana IN      A       10.0.5.5
pulse IN        A       10.0.5.8
ubuntumonitoring IN A   10.0.5.7

; Kubernetes Engine Nodes
cks-master-1   IN      A       192.168.32.8
cks-master-2   IN      A       192.168.32.9
cks-worker-1   IN      A       192.168.32.10
cks-worker-2   IN      A       192.168.32.3
cks-worker-3   IN      A       192.168.32.6
cks-worker-4   IN      A       192.168.32.7

; Zone apex points to ns1
@               IN      A       172.16.40.3
```

After saving, check the syntax:
```bash
sudo named-checkzone cybacad.lab /etc/bind/db.cybacad.lab
```

### b) `/etc/bind/db.hq.cybacad.lab`
```zone
$TTL    604800
@       IN      SOA     ns1.hq.cybacad.lab. admin.hq.cybacad.lab. (
                                                2024060201      ; Serial
                                                604800          ; Refresh
                                                86400           ; Retry
                                                2419200         ; Expire
                                                604800 )        ; Negative Cache TTL

grafana         IN      A       10.0.5.5
; Name servers
@       IN      NS      ns1.hq.cybacad.lab.

; DNS Server (static IP)
ns1     IN      A       172.16.40.3

; Monitoring Stack (Updated IPs)
prometheus      IN      A       10.0.5.4
grafana         IN      A       10.0.5.5
pulse           IN      A       10.0.5.8
ubuntumonitoring IN    A       10.0.5.7

; Convenience aliases
metrics         IN      CNAME   prometheus
monitor         IN      CNAME   grafana
```
After saving, check the syntax:
```bash
sudo named-checkzone hq.cybacad.lab /etc/bind/db.hq.cybacad.lab
```

### c) `/etc/bind/db.remote.cybacad.lab`
```zone
$TTL    604800
@       IN      SOA     ns1.remote.cybacad.lab. admin.remote.cybacad.lab. (
                                                2024060201      ; Serial
                                                604800          ; Refresh
                                                86400           ; Retry
                                                2419200         ; Expire
                                                604800 )        ; Negative Cache TTL

; Name servers
@       IN      NS      ns1.remote.cybacad.lab.

; DNS Server (static IP)
ns1     IN      A       172.16.40.3

; Remote site services (update as needed)
; web     IN      A       212.100.90.102
; api     IN      A       212.100.90.102

; Convenience aliases
; www     IN      CNAME   web
```
After saving, check the syntax:
```bash
sudo named-checkzone remote.cybacad.lab /etc/bind/db.remote.cybacad.lab
```

### d) `/etc/bind/db.services.cybacad.lab`
```zone
$TTL    604800
@       IN      SOA     ns1.services.cybacad.lab. admin.services.cybacad.lab. (
                                                2024060201      ; Serial
                                                604800          ; Refresh
                                                86400           ; Retry
                                                2419200         ; Expire
                                                604800 )        ; Negative Cache TTL

grafana         IN      A       10.0.5.5
; Name servers
@       IN      NS      ns1.services.cybacad.lab.

; DNS Server (static IP)
ns1     IN      A       172.16.40.3
dns     IN      A       172.16.40.3

; Core Services (Updated IPs)
prometheus      IN      A       10.0.5.4
grafana         IN      A       10.0.5.5
pulse           IN      A       10.0.5.8
ubuntumonitoring IN    A        10.0.5.7
wazuh          IN      A        40.10.10.10

; Service aliases
metrics         IN      CNAME   prometheus
monitor         IN      CNAME   grafana

; Future services (ready for deployment)
; cicd           IN      A       <future-cicd-ip>
; db             IN      A       <future-db-ip>
```
After saving, check the syntax:
```bash
sudo named-checkzone services.cybacad.lab /etc/bind/db.services.cybacad.lab
```

### e) `/etc/bind/db.192.168.3` (Reverse zone for 192.168.3.x)
```zone
$TTL    604800
@       IN      SOA     ns1.cybacad.lab. admin.cybacad.lab. (
                                                2024091902      ; Serial
                                                604800          ; Refresh
                                                86400           ; Retry
                                                2419200         ; Expire
                                                604800 )        ; Negative Cache TTL

@       IN      NS      ns1.cybacad.lab.

8       IN      PTR     prox1.cybacad.lab.
9       IN      PTR     prox2.cybacad.lab.
```
After saving, check the syntax:
```bash
sudo named-checkzone 3.168.192.in-addr.arpa /etc/bind/db.192.168.3
```

### f) `/etc/bind/db.192.168.32` (Reverse zone for 192.168.32.x)
```zone
$TTL    604800
@       IN      SOA     ns1.cybacad.lab. admin.cybacad.lab. (
                                                2024091902      ; Serial
                                                604800          ; Refresh
                                                86400           ; Retry
                                                2419200         ; Expire
                                                604800 )        ; Negative Cache TTL

@       IN      NS      ns1.cybacad.lab.

8       IN      PTR     cks-master-1.cybacad.lab.
9       IN      PTR     cks-master-2.cybacad.lab.
10      IN      PTR     cks-worker-1.cybacad.lab.
3       IN      PTR     cks-worker-2.cybacad.lab.
6       IN      PTR     cks-worker-3.cybacad.lab.
7       IN      PTR     cks-worker-4.cybacad.lab.
1       IN      PTR     pfsense.cybacad.lab.
2       IN      PTR     windows.cybacad.lab.
```
After saving, check the syntax:
```bash
sudo named-checkzone 32.168.192.in-addr.arpa /etc/bind/db.192.168.32
```

### g) `/etc/bind/db.10.0.5` (Reverse zone for 10.0.5.x)
```zone
$TTL    604800
@       IN      SOA     ns1.cybacad.lab. admin.cybacad.lab. (
                                                2024091902      ; Serial
                                                604800          ; Refresh
                                                86400           ; Retry
                                                2419200         ; Expire
                                                604800 )        ; Negative Cache TTL

@       IN      NS      ns1.cybacad.lab.

2       IN      PTR     nodeexp1.cybacad.lab.
3       IN      PTR     nodeexp2.cybacad.lab.
4       IN      PTR     prometheus.cybacad.lab.
5       IN      PTR     grafana.cybacad.lab.
8       IN      PTR     pulse.cybacad.lab.
7       IN      PTR     ubuntumonitoring.cybacad.lab.
```
After saving, check the syntax:
```bash
sudo named-checkzone 5.0.10.in-addr.arpa /etc/bind/db.10.0.5
```

### h) `/etc/bind/db.40.10.10` (Reverse zone for 40.10.10.x)
```zone
$TTL    604800
@       IN      SOA     ns1.cybacad.lab. admin.cybacad.lab. (
                                                2024091902      ; Serial
                                                604800          ; Refresh
                                                86400           ; Retry
                                                2419200         ; Expire
                                                604800 )        ; Negative Cache TTL

@       IN      NS      ns1.cybacad.lab.

10      IN      PTR     wazuh.cybacad.lab.
```
After saving, check the syntax:
```bash
sudo named-checkzone 10.10.10.in-addr.arpa /etc/bind/db.40.10.10
```

---

## 5. Set Permissions (Manual)

After all files are created, set the correct permissions:
```bash
sudo chown root:bind /etc/bind/db.*
sudo chmod 644 /etc/bind/db.*
```

---

## 6. Validate All Configuration

Check the main config:
```bash
sudo named-checkconf
```

Check all zones again:
```bash
for z in /etc/bind/db.*; do
    sudo named-checkzone $(basename "$z") "$z"
done
```

---

## 7. Start and Enable Bind9

```bash
sudo systemctl restart named
sudo systemctl enable named
sudo systemctl status named --no-pager
```

---

## 8. Reload Zones

```bash
sudo rndc reload || true
```

---

## 9. Test DNS Functionality (Manual)

Test from both localhost and DMZ IP:
```bash
for ip in 127.0.0.1 172.16.40.3; do
    echo "Testing via $ip..."
    dig +short @$ip ns1.cybacad.lab
    dig +short @$ip prox1.cybacad.lab
    dig +short -x 192.168.3.8 @$ip
    # ...repeat for all important records...
done
```

---

## 10. Client Configuration

Set `nameserver 172.16.40.3` in `/etc/resolv.conf` on clients, or configure DHCP/pfSense to distribute this DNS.

---

## 11. Maintenance

- To add records: edit the appropriate db.* file, increment the serial, and run `sudo rndc reload`.
- To check logs: `sudo journalctl -u named` or `sudo systemctl status named`.

---

## 12. Troubleshooting

- Use `sudo named-checkconf` and `sudo named-checkzone` for syntax.
- Use `dig` and `nslookup` to test queries.
- Check permissions: `sudo chown root:bind /etc/bind/db.* && sudo chmod 644 /etc/bind/db.*`
- Ensure BIND is listening on both 127.0.0.1 and 172.16.40.3 (see `named.conf.options`).

---

This manual process is as explicit as possible, showing every file and command needed to build your DNS server from scratch.
auto eth0
echo 'export PATH=$PATH:/usr/sbin' >> ~/.bashrc

# Bind9 DNS Server - Manual, Explicit, Step-by-Step Setup

This guide shows every single step and file content needed to manually deploy your Bind9 DNS server, with no shortcuts. You will create each config and zone file by hand, copy-pasting the exact content, and run all commands yourself. This is ideal for learning and for full transparency.

---

## Prerequisites
- Ubuntu 24.04 server (static IP: 172.16.40.3 recommended)
- Root or sudo access
- Network connectivity to other nodes

---

## 1. Configure Static IP Address

### For Ubuntu 20.04+ (Netplan)

Create the file `/etc/netplan/01-static-ip.yaml` with the following content:

```yaml
network:
    version: 2
    ethernets:
        eth0:
            dhcp4: no
            addresses: [172.16.40.3/24]
            gateway4: 172.16.40.1
            nameservers:
                addresses: [172.16.40.3, 1.1.1.1]
```

Apply the configuration and verify:

```bash
sudo netplan apply
ip addr show eth0
ip route show
```

### For older systems (/etc/network/interfaces)

Edit `/etc/network/interfaces` and add:

```ini
auto eth0
iface eth0 inet static
        address 172.16.40.3
        netmask 255.255.255.0
        gateway 172.16.40.1
        dns-nameservers 172.16.40.3 1.1.1.1
```

Restart networking:

```bash
sudo systemctl restart networking
```

---


## 3. Create Bind9 Configuration Files (Manual Copy-Paste)

You will create each config file by hand. Open the file with your editor (e.g. `sudo nano /etc/bind/named.conf.options`), erase any existing content, and paste exactly what is shown below.

### a) `/etc/bind/named.conf.options`

Open the file:
```bash
sudo nano /etc/bind/named.conf.options
```
Paste this content:
```conf
// named.conf.options - Bind9 global options

acl "trusted" {
    127.0.0.1;
    ::1;
    192.168.32.0/24;   // internal LAN - Proxmox nodes
    172.16.40.0/24;    // DMZ network
};

options {
    directory "/var/cache/bind";

    // Forwarders (internet DNS servers) - used for recursive queries from internal hosts
    forwarders {
        1.1.1.1;    // Cloudflare
        8.8.8.8;    // Google
        192.168.32.1;    // pfsense
    };

    // Listen on local + DMZ IP
    listen-on port 53 { 127.0.0.1; 172.16.40.3; };
    listen-on-v6 { none; };

    // Restrict who can query & recurse
    allow-query { trusted; };
    allow-recursion { trusted; };
    allow-transfer { none; };         // no zone transfers by default (tighten security)
    recursion yes;

    dnssec-validation auto;

    // Security options
    auth-nxdomain yes;    # conform to RFC1035
    minimal-responses yes;
};
```

---

### b) `/etc/bind/named.conf.local`

Open the file:
```bash
sudo nano /etc/bind/named.conf.local
```
Paste this content:
```conf
// Main domain
zone "cybacad.lab" {
    type master;
    file "/etc/bind/db.cybacad.lab";
    allow-transfer { none; };
};

// HQ subdomain
zone "hq.cybacad.lab" {
    type master;
    file "/etc/bind/db.hq.cybacad.lab";
    allow-transfer { none; };
};

// Remote subdomain
zone "remote.cybacad.lab" {
    type master;
    file "/etc/bind/db.remote.cybacad.lab";
    allow-transfer { none; };
};

// Services subdomain
zone "services.cybacad.lab" {
    type master;
    file "/etc/bind/db.services.cybacad.lab";
    allow-transfer { none; };
};

// Reverse zones for each subnet
zone "3.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.3";
    allow-transfer { none; };
};
zone "32.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.32";
    allow-transfer { none; };
};
zone "5.0.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.10.0.5";
    allow-transfer { none; };
};
zone "10.10.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.40.10.10";
    allow-transfer { none; };
};
```



cat /etc/resolv.conf
**Solution**: Check logs and configuration:

# Bind9 DNS Server - Manual Step-by-Step Setup (Modern Automated Structure)

## Prerequisites
- Ubuntu 24.04 server (static IP: 172.16.40.3 recommended)
- Root or sudo access
- All config and zone files from your repo (db.* files, named.conf.local, named.conf.options)

## 1. Install Bind9 and Utilities
```bash
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc dnsutils
```

## 2. Prepare Config and Zone Files
Copy all your repo files to the server (e.g. with scp):
```bash
scp db.* named.conf.local named.conf.options user@172.16.40.3:/tmp/
```

## 3. Backup Existing Configs (if any)
```bash
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak 2>/dev/null || true
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak 2>/dev/null || true
sudo cp /etc/bind/db.* /etc/bind/backup/ 2>/dev/null || true
```

## 4. Deploy New Config and Zone Files
```bash
sudo cp /tmp/named.conf.options /etc/bind/
sudo cp /tmp/named.conf.local /etc/bind/
sudo cp /tmp/db.* /etc/bind/
```

## 5. Remove Obsolete Files
```bash
sudo rm -f /etc/bind/db.192
```

## 6. Set Permissions
```bash
sudo chown root:bind /etc/bind/db.*
sudo chmod 644 /etc/bind/db.*
```

## 7. Validate Configuration
```bash
sudo named-checkconf
for z in /etc/bind/db.*; do
    sudo named-checkzone $(basename "$z") "$z"
done
```

## 8. Restart and Enable Bind9
```bash
sudo systemctl restart named
sudo systemctl enable named
sudo systemctl status named --no-pager
```

## 9. Reload Zones
```bash
sudo rndc reload || true
```

## 10. Test DNS Functionality (Forward and Reverse)
Test from both localhost and DMZ IP:
```bash
for ip in 127.0.0.1 172.16.40.3; do
    echo "Testing via $ip..."
    dig +short @$ip ns1.cybacad.lab
    dig +short @$ip prox1.cybacad.lab
    dig +short -x 192.168.3.8 @$ip
    # ...repeat for all important records...
done
```

## 11. Client Configuration
- Set `nameserver 172.16.40.3` in `/etc/resolv.conf` on clients, or configure DHCP/pfSense to distribute this DNS.

## 12. Maintenance
- To add records: edit the appropriate db.* file, increment the serial, and run `sudo rndc reload`.
- To check logs: `sudo journalctl -u named` or `sudo systemctl status named`.

## Troubleshooting
- Use `sudo named-checkconf` and `sudo named-checkzone` for syntax.
- Use `dig` and `nslookup` to test queries.
- Check permissions: `sudo chown root:bind /etc/bind/db.* && sudo chmod 644 /etc/bind/db.*`
- Ensure BIND is listening on both 127.0.0.1 and 172.16.40.3 (see `named.conf.options`).

---

This manual process exactly mirrors the automated script, so you can deploy, validate, and troubleshoot Bind9 DNS by hand if needed.
sudo named-checkzone remote.cybacad.lab /etc/bind/db.remote.cybacad.lab
