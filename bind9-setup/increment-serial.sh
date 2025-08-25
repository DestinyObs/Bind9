#!/bin/bash

# Bind9 Zone Serial Increment Script

ZONEFILE="/etc/bind/db.site1.lab"
REVERSE_ZONEFILE="/etc/bind/db.192"

increment_serial() {
    local file=$1
    local zone_name=$2
    
    if [ ! -f "$file" ]; then
        echo "Error: Zone file $file not found"
        return 1
    fi
    
    # Extract current serial
    SERIAL=$(grep -o '[0-9]\{10\}.*; Serial' "$file" | grep -o '[0-9]\{10\}')
    
    if [ -z "$SERIAL" ]; then
        echo "Error: Could not find serial number in $file"
        return 1
    fi
    
    # Generate new serial (YYYYMMDDNN format)
    DATE=$(date +%Y%m%d)
    PREFIX=${SERIAL:0:8}
    SUFFIX=${SERIAL:8:2}
    
    if [ "$PREFIX" == "$DATE" ]; then
        # Same date, increment sequence
        NN=$((10#$SUFFIX + 1))
        NEWSERIAL="${DATE}$(printf "%02d" $NN)"
    else
        # New date, start with 01
        NEWSERIAL="${DATE}01"
    fi
    
    echo "Updating $file: $SERIAL -> $NEWSERIAL"
    
    # Replace serial number
    sed -i "s/$SERIAL/$NEWSERIAL/" "$file"
    
    # Validate zone file
    if named-checkzone "$zone_name" "$file" > /dev/null 2>&1; then
        echo "  ✓ Zone file syntax is valid"
        
        # Reload the zone
        if rndc reload "$zone_name" > /dev/null 2>&1; then
        echo "Zone file valid"
        # Reload zone
        if rndc reload "$zone_name" > /dev/null 2>&1; then
            echo "Zone reloaded successfully"
        else
            echo "Zone reload failed, trying full restart"
            systemctl reload bind9
        fi
    else
        echo "Zone file syntax error after update"
        return 1
    fi
    
    return 0
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Update zones
echo "Updating zones..."
increment_serial "$ZONEFILE" "site1.lab"
increment_serial "$REVERSE_ZONEFILE" "75.168.192.in-addr.arpa"
echo "Serial increment complete"
