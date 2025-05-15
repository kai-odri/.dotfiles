#!/usr/bin/env bash

# Quad9 DNS servers
#DNS_IPV4="9.9.9.9 149.112.112.112"
#DNS_IPV6="2620:fe::fe 2620:fe::9"
DNS_IPV4="127.0.0.1"
# Patterns to ignore (VPNs, virtuals, loopback)
ignore_patterns=("^lo$" "^wg" "^virbr" "^vnet" "^tap")

# Function to check if connection should be ignored
should_ignore() {
    local conn="$1"
    for pattern in "${ignore_patterns[@]}"; do
        if [[ "$conn" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Read all active connections line-by-line to preserve spaces
nmcli -t -f NAME con show --active | while IFS= read -r conn; do
    if should_ignore "$conn"; then
        echo "⏭ Skipping excluded connection: $conn"
        continue
    fi

    echo "🔧 Setting Quad9 DNS for: \"$conn\""

    nmcli con modify "$conn" ipv4.dns "$DNS_IPV4"
    nmcli con modify "$conn" ipv4.ignore-auto-dns yes

    nmcli con modify "$conn" ipv6.dns "$DNS_IPV6"
    nmcli con modify "$conn" ipv6.ignore-auto-dns yes

    nmcli con down "$conn" && nmcli con up "$conn"
done

echo "✅ Quad9 DNS applied (except excluded interfaces)."

