#!/bin/bash

# DNS Testing Script
# Run this after Bind9 setup to verify everything is working

echo "====================================="
echo "DNS Testing Script"
echo "====================================="
echo "Testing DNS resolution for site1.lab"
echo ""

DNS_SERVER="192.168.75.6"
DOMAIN="site1.lab"

# Test if dig is available
if ! command -v dig &> /dev/null; then
    echo "dig command not found. Installing dnsutils..."
    sudo apt update && sudo apt install -y dnsutils
fi

echo "Testing DNS server: $DNS_SERVER"
echo "Domain: $DOMAIN"
echo ""

# Test 1: Local DNS server response
echo "Test 1: Testing local DNS server response..."
if dig @127.0.0.1 $DOMAIN SOA +short > /dev/null 2>&1; then
    echo "✓ Local DNS server is responding"
    dig @127.0.0.1 $DOMAIN SOA +short
else
    echo "✗ Local DNS server is not responding"
fi
echo ""

# Test 2: Forward lookups (A records)
echo "Test 2: Testing forward lookups (A records)..."

hosts=("ns1" "prox1" "prox2" "prox3" "prox4" "wazuh" "prometheus" "grafana" "mssql")

for host in "${hosts[@]}"; do
    result=$(dig @$DNS_SERVER $host.$DOMAIN A +short 2>/dev/null)
    if [ -n "$result" ]; then
        echo "✓ $host.$DOMAIN -> $result"
    else
        echo "✗ $host.$DOMAIN -> No response"
    fi
done
echo ""

# Test 3: Reverse lookups (PTR records)
echo "Test 3: Testing reverse lookups (PTR records)..."

ips=("192.168.75.1" "192.168.75.4" "192.168.75.5" "192.168.75.6" "192.168.75.8")

for ip in "${ips[@]}"; do
    result=$(dig @$DNS_SERVER -x $ip +short 2>/dev/null)
    if [ -n "$result" ]; then
        echo "✓ $ip -> $result"
    else
        echo "✗ $ip -> No PTR record"
    fi
done
echo ""

# Test 4: CNAME records
echo "Test 4: Testing CNAME records..."

cnames=("db" "sql" "monitor" "metrics")

for cname in "${cnames[@]}"; do
    result=$(dig @$DNS_SERVER $cname.$DOMAIN CNAME +short 2>/dev/null)
    if [ -n "$result" ]; then
        echo "✓ $cname.$DOMAIN -> $result"
    else
        echo "✗ $cname.$DOMAIN -> No CNAME record"
    fi
done
echo ""

# Test 5: External resolution (forwarders)
echo "Test 5: Testing external resolution (forwarders)..."

external_hosts=("google.com" "cloudflare.com" "github.com")

for host in "${external_hosts[@]}"; do
    result=$(dig @$DNS_SERVER $host A +short 2>/dev/null | head -1)
    if [ -n "$result" ]; then
        echo "✓ $host -> $result"
    else
        echo "✗ $host -> No response"
    fi
done
echo ""

# Test 6: NS record
echo "Test 6: Testing NS record..."
result=$(dig @$DNS_SERVER $DOMAIN NS +short 2>/dev/null)
if [ -n "$result" ]; then
    echo "✓ NS record: $result"
else
    echo "✗ No NS record found"
fi
echo ""

# Test 7: Zone transfer (should be denied)
echo "Test 7: Testing zone transfer security (should be denied)..."
result=$(dig @$DNS_SERVER $DOMAIN AXFR 2>&1)
if echo "$result" | grep -q "Transfer failed"; then
    echo "✓ Zone transfer properly denied"
elif echo "$result" | grep -q "refused"; then
    echo "✓ Zone transfer properly refused"
else
    echo "⚠ Zone transfer test inconclusive"
fi
echo ""

# Summary
echo "====================================="
echo "DNS Testing Complete"
echo "====================================="
echo ""
echo "If all tests show ✓, your DNS server is working correctly!"
echo ""
echo "To configure clients to use this DNS server:"
echo "1. Set DNS server to 192.168.75.6 in network settings"
echo "2. Or configure pfSense DHCP to distribute this DNS server"
echo ""
echo "Troubleshooting:"
echo "- Check logs: sudo journalctl -u bind9 --since '5 minutes ago'"
echo "- Check service: sudo systemctl status bind9"
echo "- Validate config: sudo named-checkconf"
echo ""
