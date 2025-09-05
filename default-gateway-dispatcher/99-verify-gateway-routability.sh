#!/bin/bash

# NetworkManager Dispatcher Script
#
# PURPOSE:
# When a connection comes 'up', this script pings its default gateway
# to verify real connectivity. This is useful for dealing with buggy
# Wi-Fi APs that allow a connection but don't pass traffic.
# All output is logged to the systemd journal via `logger`.
#
# VIEW LOGS WITH:
# journalctl -t nm-gateway-check -f
#
# LOGIC:
# 1. Triggers only on the 'up' state for a connection.
# 2. Finds the default gateway for the specific interface that connected.
# 3. Pings the gateway up to 10 times.
# 4. If any ping succeeds, the script logs it and exits silently.
# 5. If all 10 pings fail, it logs the failure and disconnects the network.

MAX_ATTEMPTS=10
LOGGER_TAG="nm-gateway-check"

INTERFACE="$1" # The network interface in use (e.g., wlan0)
ACTION="$2"    # The action being performed (e.g., up, down)

run_connectivity_check() {
    local conn_id="$1"
    local iface="$2"

    echo "---" | logger -t "$LOGGER_TAG"
    echo "Check triggered for '$conn_id' on interface '$iface'." | logger -t "$LOGGER_TAG"

    # Give the connection a moment to establish its routes.
    sleep 3

    # Dynamically find the default gateway for this specific interface.
    local gateway_ip
    gateway_ip=$(ip route show dev "$iface" | grep '^default' | awk '{print $3}')

    if [ -z "$gateway_ip" ]; then
        echo "No default gateway found for '$iface'. Check stopping." | logger -t "$LOGGER_TAG"
        exit 0
    fi

    echo "Found gateway '$gateway_ip'. Pinging up to $MAX_ATTEMPTS times..." | logger -t "$LOGGER_TAG"

    for i in $(seq 1 "$MAX_ATTEMPTS"); do
        # Ping once with a 2-second timeout.
        if ping -c 1 -W 2 "$gateway_ip" &>/dev/null; then
            echo "Ping to '$gateway_ip' SUCCEEDED on attempt $i. Network is functional." | logger -t "$LOGGER_TAG"
            # Exit the background script successfully.
            exit 0
        fi
        # If ping failed, wait a second before the next try.
        sleep 1
    done

    # If the loop completes, it means all attempts failed.
    echo "All $MAX_ATTEMPTS pings to '$gateway_ip' FAILED. Disconnecting '$conn_id'." | logger -t "$LOGGER_TAG"
    nmcli connection down "$conn_id"
}

echo "Action logged on $CONNECTION_ID on $INTERFACE: $ACTION" | logger -t "$LOGGER_TAG"

# --- Dispatcher Entry Point ---
# We only care about the 'up' action.
if [ "$ACTION" = "up" ]; then
    # Run the check in a background process (&) so it doesn't block
    # NetworkManager or the boot process.
    run_connectivity_check "$CONNECTION_ID" "$INTERFACE" &
fi

exit 0
