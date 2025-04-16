#!/bin/bash
set -e

# Function to create TCP tunnel
create_tcp_tunnel() {
    local hostname=$1
    local local_port=$2

    cloudflared tunnel route ip \
        --hostname "$hostname" \
        --destination "localhost:$local_port"
}

# Function to create access tunnel
create_access_tunnel() {
    local hostname=$1
    local local_port=$2
    
    cloudflared access tcp \
        --hostname "$hostname" \
        --url "localhost:$local_port"
}

# Main tunnel creation logic
main() {
    local mode=${TUNNEL_ROUTE_MODE:-"tcp"}
    
    # Split comma-separated hostname:port pairs
    IFS=',' read -ra TUNNELS <<< "$CLOUDFLARE_HOSTNAMES"
    IFS=',' read -ra PORTS <<< "$LOCAL_PORTS"
    
    for i in "${!TUNNELS[@]}"; do
        hostname="${TUNNELS[i]}"
        port="${PORTS[i]}"
        
        case "$mode" in
            "tcp")
                create_tcp_tunnel "$hostname" "$port"
                ;;
            "access")
                create_access_tunnel "$hostname" "$port"
                ;;
            *)
                echo "Invalid tunnel mode. Use 'tcp' or 'access'."
                exit 1
                ;;
        esac
    done
}

main "$@"

