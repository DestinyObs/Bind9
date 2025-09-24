
# Nginx Reverse Proxy for Lab Services (with HTTPS & Let's Encrypt)

This folder contains a standalone, production-ready Nginx reverse proxy configuration for all web-accessible services in your lab, with **full HTTPS support and automatic Let's Encrypt certificate management for every domain**. It is designed to be independent of your DNS setup and can be deployed on any server (physical or VM) with access to your internal network.

## Purpose
- Provide a single entry point for all lab web services (monitoring, security, infrastructure, etc.)
- Allow users to access services by friendly domain names (e.g., `grafana.cybacad.lab`) without specifying ports
- Enforce consistent proxy, security, and logging policies
- Decouple web access from DNS server location or implementation
- **Secure all traffic with HTTPS and trusted certificates**

## Supported Domains & Services
This proxy is pre-configured for all domains and services defined in your DNS:
- grafana.cybacad.lab → Grafana dashboards (10.0.5.5:3000)
- prometheus.cybacad.lab → Prometheus monitoring (10.0.5.4:9090)
- pulse.cybacad.lab → Pulse service (10.0.5.8:8080)
- wazuh.cybacad.lab → Wazuh security (40.10.10.10:5601 or as needed)
- pfsense.cybacad.lab → pfSense web UI (192.168.32.1:443 or as needed)
- prox1.cybacad.lab, prox2.cybacad.lab → Proxmox web UI (192.168.3.8:8006, 192.168.3.9:8006)
- nodeexp1.cybacad.lab, nodeexp2.cybacad.lab → Node Exporters (10.0.5.2:9100, 10.0.5.3:9100)
- windows.cybacad.lab → Windows admin (RDP Gateway or web, as needed)
- Add more as your environment grows

## How It Works
- Nginx listens on ports 80 (HTTP) and 443 (HTTPS)
- **All HTTP traffic is automatically redirected to HTTPS**
- For each domain, a `server` block proxies requests to the correct backend IP and port
- All proxy headers are set for compatibility with web apps
- Let's Encrypt certificates are automatically requested and renewed for every domain
- No dependency on the DNS server location—just ensure the proxy host can resolve the service hostnames or use IPs

## Deployment Steps (Automated)
1. Ensure your server is running Ubuntu/Debian and has Docker installed
2. Edit backend IPs/ports in `nginx.conf` as needed for your environment
3. Update the `EMAIL` variable in `deploy_nginx.sh` if you want Let's Encrypt notifications to go to a different address
4. Run the deployment script:
	 ```bash
	 cd reverseproxy-nginx
	 chmod +x deploy_nginx.sh
	 ./deploy_nginx.sh
	 ```
	 - This will:
		 - Install certbot if needed
		 - Obtain/renew Let's Encrypt certificates for all domains
		 - Download recommended SSL config if needed
		 - Start the Nginx container with all necessary volumes and ports
		 - Mount `/etc/letsencrypt` into the container for live certs
		 - Test and reload Nginx
5. Update your DNS so all service domains point to the proxy server's IP

## Certificate Renewal
- Let's Encrypt certificates are valid for 90 days
- To renew all certificates and reload Nginx, run:
	```bash
	sudo certbot renew --deploy-hook 'sudo docker exec lab-nginx-reverseproxy nginx -s reload'
	```
- You can automate this with a cron job for true zero-downtime SSL

## Security & Best Practices
- Only expose the proxy server to trusted networks
- Use firewall rules to restrict access if needed
- For admin interfaces (pfSense, Proxmox, etc.), consider additional authentication or IP whitelisting
- Regularly update Nginx, Docker, and monitor logs
- **All traffic is encrypted with trusted certificates**

## Extending This Setup
- Add new `server` blocks for new services as your lab grows
- Use `upstream` blocks for load balancing or failover
- Add rate limiting, caching, or WAF modules as needed
- For troubleshooting, check Nginx logs and certbot output

---

This reverse proxy is designed to be robust, maintainable, and independent of your DNS implementation. All configuration is explicit, fully documented, and can be audited or extended as your environment evolves. **HTTPS is enforced for all domains by default.**
