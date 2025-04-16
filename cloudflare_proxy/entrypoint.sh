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
if [ ! -f "/etc/haproxy/haproxy.cfg" ] || [ ! -s "/etc/haproxy/haproxy.cfg" ]; then
	    cat > /etc/haproxy/haproxy.cfg << EOF
global
    log 127.0.0.1 local0
    maxconn 4096
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    retries 3
    maxconn 2000
    timeout connect 5s
    timeout client  30s
    timeout server  30s

# Add your backend configurations here
EOF
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
