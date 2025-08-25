#!/bin/bash

# Package all Bind9 setup files into a transferable archive
# Run this script to create a deployment-ready package

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NAME="bind9-setup-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Creating Bind9 DNS setup package..."
echo "Package name: $PACKAGE_NAME"

# Create the package
cd "$SCRIPT_DIR"
tar -czf "$PACKAGE_NAME" \
    --exclude="$PACKAGE_NAME" \
    --exclude="create-package.sh" \
    --exclude=".git*" \
    *

if [ $? -eq 0 ]; then
    echo "✓ Package created successfully: $PACKAGE_NAME"
    echo ""
    echo "To deploy on your DNS server (192.168.75.6):"
    echo "1. Copy package: scp $PACKAGE_NAME user@192.168.75.6:~/"
    echo "2. SSH to server: ssh user@192.168.75.6"
    echo "3. Extract: tar -xzf $PACKAGE_NAME"
    echo "4. Run setup: cd bind9-setup && sudo ./setup-bind9.sh"
    echo ""
    echo "Package contents:"
    tar -tzf "$PACKAGE_NAME" | sort
else
    echo "✗ Package creation failed"
    exit 1
fi
