#!/bin/bash
set -e

# Validate required environment variables
if [ -z "$ACCOUNT_TAG" ] || [ -z "$TUNNEL_ID" ] || [ -z "$TUNNEL_SECRET" ]; then
    echo "Error: ACCOUNT_TAG, TUNNEL_ID and TUNNEL_SECRET must be provided"
    exit 1
fi

# Create tunnel credentials file
mkdir -p /etc/cloudflared
cat > /etc/cloudflared/tunnel.json << EOF
{
  "AccountTag": "$ACCOUNT_TAG",
  "TunnelID": "$TUNNEL_ID",
  "TunnelSecret": "$TUNNEL_SECRET"
}
EOF

# Check if config.yml exists and is empty
if [ ! -s "/etc/cloudflared/config.yml" ]; then
    cat > /etc/cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: /etc/cloudflared/tunnel.json
ingress:
  - service: http_status:404
    match: "*"
EOF
fi

# Custom HAProxy config
if [ -f "/custom-haproxy.cfg" ]; then
    cp /custom-haproxy.cfg /etc/haproxy/haproxy.cfg
fi

# Enhanced monitoring and restart function
monitor_processes() {
    while true; do
        # Check if processes are running
        if ! pgrep cloudflared > /dev/null; then
            echo "Cloudflared process died. Restarting..."
            cloudflared tunnel run $TUNNEL_ID &
        fi

        if ! pgrep haproxy > /dev/null; then
            echo "HAProxy process died. Restarting..."
            haproxy -f /etc/haproxy/haproxy.cfg &
        fi

        # Sleep to prevent tight looping
        sleep 15
    done
}

# Start services with monitoring
cloudflared tunnel run $TUNNEL_ID &
haproxy -f /etc/haproxy/haproxy.cfg &

# Start background monitoring
monitor_processes
