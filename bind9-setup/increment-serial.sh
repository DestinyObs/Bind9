#!/bin/bash

# Bind9 Zone Serial Increment Script
# This script automatically increments the serial number in zone files
# and reloads the zone

ZONEFILE="/etc/bind/db.site1.lab"
REVERSE_ZONEFILE="/etc/bind/db.192"

# Function to increment serial in a file
increment_serial() {
    local file=$1
    local zone_name=$2
    
    if [ ! -f "$file" ]; then
        echo "Error: Zone file $file not found"
        return 1
    fi
    
    # Extract current serial number
    SERIAL=$(grep -o '[0-9]\{10\}.*; Serial' "$file" | grep -o '[0-9]\{10\}')
    
    if [ -z "$SERIAL" ]; then
        echo "Error: Could not find serial number in $file"
        return 1
    fi
    
    # Generate new serial (format: YYYYMMDDNN)
    DATE=$(date +%Y%m%d)
    PREFIX=${SERIAL:0:8}
    SUFFIX=${SERIAL:8:2}
    
    if [ "$PREFIX" == "$DATE" ]; then
        # Same date, increment the sequence number
        NN=$((10#$SUFFIX + 1))
        NEWSERIAL="${DATE}$(printf "%02d" $NN)"
    else
        # New date, start with 01
        NEWSERIAL="${DATE}01"
    fi
    
    echo "Updating $file:"
    echo "  Old serial: $SERIAL"
    echo "  New serial: $NEWSERIAL"
    
    # Replace the serial number
    sed -i "s/$SERIAL/$NEWSERIAL/" "$file"
    
    # Validate the zone file
    if named-checkzone "$zone_name" "$file" > /dev/null 2>&1; then
        echo "  ✓ Zone file syntax is valid"
        
        # Reload the zone
        if rndc reload "$zone_name" > /dev/null 2>&1; then
            echo "  ✓ Zone reloaded successfully"
        else
            echo "  ⚠ Zone reload failed, trying full restart..."
            systemctl reload bind9
        fi
    else
        echo "  ✗ Zone file syntax error after update"
        return 1
    fi
    
    return 0
}

# Main script
echo "====================================="
echo "Bind9 Zone Serial Increment Script"
echo "====================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Increment forward zone
echo "Updating forward zone (site1.lab)..."
if increment_serial "$ZONEFILE" "site1.lab"; then
    echo "✓ Forward zone updated successfully"
else
    echo "✗ Forward zone update failed"
    exit 1
fi

echo ""

# Increment reverse zone
echo "Updating reverse zone (75.168.192.in-addr.arpa)..."
if increment_serial "$REVERSE_ZONEFILE" "75.168.192.in-addr.arpa"; then
    echo "✓ Reverse zone updated successfully"
else
    echo "✗ Reverse zone update failed"
    exit 1
fi

echo ""
echo "====================================="
echo "Serial increment complete!"
echo "====================================="
echo ""
echo "Both zones have been updated and reloaded."
echo "You can now test the changes with:"
echo "  dig @192.168.75.6 site1.lab SOA"
echo ""
