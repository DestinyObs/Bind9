# External/Public DNS Recommendations

## Overview
This document explains how to handle public DNS for your Site 2 web server while keeping internal DNS secure.

## Architecture Separation

### Internal DNS (Bind9 - This Setup)
- **Purpose**: Internal name resolution for site1.lab
- **Scope**: 192.168.75.0/24 network only
- **Services**: Proxmox nodes, pfSense, internal services
- **Security**: No WAN exposure, restricted queries

### External/Public DNS (Registrar/Cloud)
- **Purpose**: Public website DNS (yourcompany.com)
- **Scope**: Internet-facing
- **Services**: Web server, mail, public APIs
- **Provider**: Domain registrar or cloud DNS service

## Recommended Public DNS Providers

### Option 1: Domain Registrar DNS
- **Pros**: Simple, included with domain
- **Cons**: Basic features, limited automation
- **Best for**: Simple websites, low traffic

### Option 2: Cloudflare DNS (Recommended)
- **Pros**: Free, fast, DDoS protection, API automation
- **Cons**: None significant
- **Best for**: Production websites, high availability

### Option 3: AWS Route 53
- **Pros**: Enterprise features, AWS integration
- **Cons**: Costs money, complex for simple sites
- **Best for**: AWS-hosted applications

### Option 4: Google Cloud DNS
- **Pros**: Google infrastructure, good performance
- **Cons**: Requires Google Cloud account
- **Best for**: Google Cloud integrated setups

## Example Public DNS Configuration

### Scenario: Your public domain is `yourcompany.com`

#### Public DNS Records (Cloudflare/Registrar):
```dns
; A record pointing to your public IP
yourcompany.com.           A    203.0.113.10   ; Your public IP
www.yourcompany.com.       A    203.0.113.10   ; Your public IP

; Optional subdomain for web app
app.yourcompany.com.       A    203.0.113.10   ; Your public IP
api.yourcompany.com.       A    203.0.113.10   ; Your public IP
```

#### pfSense NAT Configuration:
```bash
# Port forwards from public IP to internal web server
WAN Port 80  → 10.10.20.5:80   (Web Server in Site 2)
WAN Port 443 → 10.10.20.5:443  (Web Server in Site 2)
```

#### HAProxy Configuration (DMZ):
```bash
# HAProxy routes traffic to Site 2 web server
frontend web_frontend
    bind *:80
    bind *:443
    redirect scheme https if !{ ssl_fc }
    default_backend web_servers

backend web_servers
    server web1 10.10.20.5:443 check ssl verify none
```

## DNS Flow Architecture

### Internal Requests (site1.lab)
```
Client → pfSense DNS → Bind9 (192.168.75.6) → Response
Example: grafana.site1.lab → 192.168.75.5
```

### External Requests (yourcompany.com)
```
Client → Public DNS (Cloudflare) → Public IP → pfSense → HAProxy → Web Server
Example: www.yourcompany.com → 203.0.113.10 → Site 2 Web Server
```

### Mixed Requests (Internal client accessing external)
```
Internal Client → Bind9 forwarders → Cloudflare/Google → Response
Example: Internal user accessing google.com
```

## pfSense Configuration for Dual DNS

### DNS Resolver Configuration
```bash
# Services → DNS Resolver
General Settings:
- Enable DNS Resolver: ✓
- Listen Port: 53
- Network Interfaces: LAN

Forwarding:
- Enable Forwarding Mode: ✓
- Use SSL/TLS for outgoing DNS Queries: ✓ (optional)

DNS Query Forwarding:
- System Domain Local Zone Type: Transparent
- Forward all reverse lookups: ✓

Custom Forwarders:
- 192.168.75.6 (Internal Bind9)
- 1.1.1.1 (Cloudflare)
- 8.8.8.8 (Google)
```

### DHCP Configuration
```bash
# Services → DHCP Server → LAN
DNS Servers:
- Primary: 192.168.75.6 (Internal DNS)
- Secondary: 1.1.1.1 (External fallback)

Domain Name: site1.lab
```

## Security Considerations

### What NOT to do:
- ❌ Don't expose Bind9 (port 53) to WAN
- ❌ Don't put internal hostnames in public DNS
- ❌ Don't use same DNS server for internal and public

### What TO do:
- ✅ Use separate DNS providers for internal vs public
- ✅ Keep internal DNS isolated to LAN
- ✅ Use HAProxy/reverse proxy for web traffic
- ✅ Monitor DNS query logs

## Automation and Integration

### Cloudflare API Example (Future)
```bash
# Update public DNS via API when public IP changes
curl -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
     -H "Authorization: Bearer $api_token" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"yourcompany.com","content":"NEW_PUBLIC_IP"}'
```

### Let's Encrypt Integration
```bash
# HAProxy can handle SSL certificates via Let's Encrypt
# Certificates are validated against public DNS
certbot --standalone -d yourcompany.com -d www.yourcompany.com
```

### Future Kubernetes Integration
```yaml
# External DNS can manage public records
apiVersion: v1
kind: Service
metadata:
  name: web-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.yourcompany.com
spec:
  type: LoadBalancer
  # External DNS controller updates Cloudflare automatically
```

## Monitoring and Troubleshooting

### Test Internal DNS
```bash
# From internal client
dig prox1.site1.lab          # Should resolve via Bind9
dig yourcompany.com          # Should resolve via public DNS
```

### Test External Access
```bash
# From internet
dig yourcompany.com          # Should return public IP
curl -I http://yourcompany.com  # Should reach web server
```

### DNS Propagation Check
```bash
# Check if public DNS changes have propagated
dig @8.8.8.8 yourcompany.com
dig @1.1.1.1 yourcompany.com
```

## Summary

This architecture provides:

1. **Security**: Internal DNS never exposed to internet
2. **Performance**: Fast internal resolution, public CDN for external
3. **Reliability**: Separate failure domains for internal vs public
4. **Scalability**: Easy to add services without exposing internal infrastructure
5. **Compliance**: Proper separation of internal and external DNS

The current Bind9 setup is perfectly designed for this architecture and already includes all necessary security measures!
