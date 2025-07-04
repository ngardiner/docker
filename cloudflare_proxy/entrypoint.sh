#!/bin/bash
set -e

# Function to setup Tailscale
setup_tailscale() {
    if [ "$TAILSCALE_ENABLE" = "true" ]; then
        echo "Setting up Tailscale..."
        
        if [ -z "$TAILSCALE_AUTHKEY" ]; then
            echo "Error: TAILSCALE_AUTHKEY must be provided when TAILSCALE_ENABLE=true"
            exit 1
        fi
        
        # Start tailscaled daemon
        tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
        
        # Wait for tailscaled to start
        sleep 3
        
        # Build tailscale up command
        TAILSCALE_CMD="tailscale up --authkey=$TAILSCALE_AUTHKEY"
        
        if [ -n "$TAILSCALE_HOSTNAME" ]; then
            TAILSCALE_CMD="$TAILSCALE_CMD --hostname=$TAILSCALE_HOSTNAME"
        fi
        
        if [ -n "$TAILSCALE_ADVERTISE_ROUTES" ]; then
            TAILSCALE_CMD="$TAILSCALE_CMD --advertise-routes=$TAILSCALE_ADVERTISE_ROUTES"
        fi
        
        if [ "$TAILSCALE_ACCEPT_ROUTES" = "true" ]; then
            TAILSCALE_CMD="$TAILSCALE_CMD --accept-routes"
        fi
        
        if [ "$TAILSCALE_ACCEPT_DNS" = "true" ]; then
            TAILSCALE_CMD="$TAILSCALE_CMD --accept-dns"
        fi
        
        # Connect to Tailscale
        eval $TAILSCALE_CMD
        
        echo "Tailscale setup completed"
    fi
}

# Validate required environment variables based on proxy mode
validate_environment() {
    case "$PROXY_MODE" in
        "cloudflare")
            if [ -z "$ACCOUNT_TAG" ] || [ -z "$TUNNEL_ID" ] || [ -z "$TUNNEL_SECRET" ]; then
                echo "Error: For cloudflare mode, ACCOUNT_TAG, TUNNEL_ID and TUNNEL_SECRET must be provided"
                exit 1
            fi
            ;;
        "tailscale")
            if [ "$TAILSCALE_ENABLE" != "true" ]; then
                echo "Error: For tailscale mode, TAILSCALE_ENABLE must be set to true"
                exit 1
            fi
            ;;
        "hybrid")
            if [ -z "$ACCOUNT_TAG" ] || [ -z "$TUNNEL_ID" ] || [ -z "$TUNNEL_SECRET" ]; then
                echo "Error: For hybrid mode, ACCOUNT_TAG, TUNNEL_ID and TUNNEL_SECRET must be provided"
                exit 1
            fi
            if [ "$TAILSCALE_ENABLE" != "true" ]; then
                echo "Error: For hybrid mode, TAILSCALE_ENABLE must be set to true"
                exit 1
            fi
            ;;
        *)
            echo "Error: PROXY_MODE must be one of: cloudflare, tailscale, hybrid"
            exit 1
            ;;
    esac
}

# Function to setup Cloudflare tunnel
setup_cloudflare() {
    if [ "$PROXY_MODE" = "cloudflare" ] || [ "$PROXY_MODE" = "hybrid" ]; then
        echo "Setting up Cloudflare tunnel..."
        
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
        
        echo "Cloudflare tunnel setup completed"
    fi
}

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
        # Check if the reload flag is set and HAProxy is enabled
        if [ -f /etc/haproxy/.reload ] && [ "$HAPROXY_ENABLE" = "true" ]; then
            rm /etc/haproxy/.reload
            echo "Reloading haproxy"
            pkill -HUP haproxy
        fi
        if [ -f /etc/cloudflared/.reload ]; then
            rm /etc/cloudflared/.reload
            echo "Reloading cloudflared"
            pkill -HUP cloudflared
        fi

        # Check if processes are running based on proxy mode
        if [ "$PROXY_MODE" = "cloudflare" ] || [ "$PROXY_MODE" = "hybrid" ]; then
            if ! pgrep cloudflared > /dev/null; then
                echo "Cloudflared process died. Restarting..."
                cloudflared tunnel run $TUNNEL_ID &
            fi
        fi

        if [ "$TAILSCALE_ENABLE" = "true" ]; then
            if ! pgrep tailscaled > /dev/null; then
                echo "Tailscaled process died. Restarting..."
                tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
            fi
        fi

        if [ "$HAPROXY_ENABLE" = "true" ] && ! pgrep haproxy > /dev/null; then
            echo "HAProxy process died. Restarting..."
            haproxy -f /etc/haproxy/haproxy.cfg &
        fi

        # Sleep to prevent tight looping
        sleep 15
    done
}

# Validate environment and setup services
validate_environment
setup_tailscale
setup_cloudflare

# Start services based on proxy mode
if [ "$PROXY_MODE" = "cloudflare" ] || [ "$PROXY_MODE" = "hybrid" ]; then
    echo "Starting Cloudflare tunnel..."
    cloudflared tunnel run $TUNNEL_ID &
fi

# Start HAProxy if enabled
if [ "$HAPROXY_ENABLE" = "true" ]; then
    echo "Starting HAProxy..."
    haproxy -f /etc/haproxy/haproxy.cfg &
else
    echo "HAProxy is disabled, skipping..."
fi

# Start background monitoring
monitor_processes
