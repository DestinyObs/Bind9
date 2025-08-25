#!/bin/bash

# DNS Testing Script

echo "DNS Testing Script"
echo "Testing DNS server on 172.16.25.2"

DNS_SERVER="172.16.25.2"

# Check if dig is available
if ! command -v dig &> /dev/null; then
    echo "Installing dnsutils..."
    sudo apt update && sudo apt install -y dnsutils
fi

# Test local DNS response
echo "Test 1: Local DNS server response"
if dig @127.0.0.1 site1.lab SOA +short > /dev/null; then
    echo "Local DNS server responding"
else
    echo "Local DNS server not responding"
fi

# Test forward lookups
echo "Test 2: Forward lookups"
hosts=("ns1" "prox1" "prox2" "prox3" "prox4")
for host in "${hosts[@]}"; do
    result=$(dig @$DNS_SERVER $host.site1.lab A +short 2>/dev/null)
    if [ -n "$result" ]; then
        echo "$host.site1.lab -> $result"
    else
        echo "$host.site1.lab -> No response"
    fi
done
echo "Test 3: Testing reverse lookups (PTR records)..."

ips=("192.168.75.1" "192.168.75.4" "192.168.75.5" "192.168.75.6" "192.168.75.8")

for ip in "${ips[@]}"; do
    result=$(dig @$DNS_SERVER -x $ip +short 2>/dev/null)
    if [ -n "$result" ]; then
        echo "✓ $ip -> $result"
    else
        echo "✗ $ip -> No PTR record"
# Test reverse lookups
echo "Test 3: Reverse lookups"
ips=("192.168.75.4" "192.168.75.5" "192.168.75.6" "192.168.75.8")
for ip in "${ips[@]}"; do
    result=$(dig @$DNS_SERVER -x $ip +short 2>/dev/null)
    if [ -n "$result" ]; then
        echo "$ip -> $result"
    else
        echo "$ip -> No PTR record"
    fi
done

# Test external resolution
echo "Test 4: External resolution"
external=("google.com" "cloudflare.com")
for host in "${external[@]}"; do
    result=$(dig @$DNS_SERVER $host A +short 2>/dev/null | head -1)
    if [ -n "$result" ]; then
        echo "$host -> $result"
    else
        echo "$host -> No response"
    fi
done

echo "DNS testing complete"
