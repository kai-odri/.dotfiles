#!/bin/bash

# Log file location
LOG_FILE="$dotfiles/logs/quad9-dns-dispatcher.log"

# Quad9 DNS servers
DNS_IPV4="9.9.9.9 149.112.112.112"
DNS_IPV6="2620:fe::fe 2620:fe::9"

# Patterns to ignore (VPNs, virtual interfaces, loopback)
ignore_patterns=("^lo$" "^wg" "^virbr" "^vnet" "^tap")

# Function to check if the connection should be ignored
should_ignore() {
    local conn="$1"
    for pattern in "${ignore_patterns[@]}"; do
        if [[ "$conn" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Detect the event
INTERFACE="$1"
STATUS="$2"

# Log the event
echo "$(date) - Event detected for interface: $INTERFACE, Status: $STATUS" >> "$LOG_FILE"

# Only act on 'up' event
if [ "$STATUS" == "up" ]; then
    # Get the connection name
    connection_name=$(nmcli -t -f NAME con show --active | grep "$INTERFACE")

    # Check if the connection should be ignored
    if should_ignore "$connection_name"; then
        echo "$(date) - Skipping ignored connection: $connection_name" >> "$LOG_FILE"
        exit 0
    fi

    echo "$(date) - Setting Quad9 DNS for connection: $connection_name" >> "$LOG_FILE"

    # Apply DNS settings
    nmcli con modify "$connection_name" ipv4.dns "$DNS_IPV4" >> "$LOG_FILE" 2>&1
    nmcli con modify "$connection_name" ipv4.ignore-auto-dns yes >> "$LOG_FILE" 2>&1

    nmcli con modify "$connection_name" ipv6.dns "$DNS_IPV6" >> "$LOG_FILE" 2>&1
    nmcli con modify "$connection_name" ipv6.ignore-auto-dns yes >> "$LOG_FILE" 2>&1

    # Restart the connection to apply the DNS
    nmcli con down "$connection_name" >> "$LOG_FILE" 2>&1
    nmcli con up "$connection_name" >> "$LOG_FILE" 2>&1

    echo "$(date) - DNS settings applied and connection restarted for: $connection_name" >> "$LOG_FILE"
else
    echo "$(date) - Connection status not 'up' for: $INTERFACE" >> "$LOG_FILE"
fi

exit 0
