# Cloudflare/Tailscale Proxy Container

## Overview
This Docker container provides a flexible, multi-purpose proxy with support for both Cloudflare tunnels and Tailscale networking, featuring HAProxy load balancing.

## Features
- Modular Cloudflare tunnel proxy support
- Tailscale VPN connectivity support
- Support for hybrid mode (both Cloudflare and Tailscale)
- Dynamic access tunnel configuration to allow mapping of Cloudflare Tunnels to local ports
- HAProxy load balancing for High Availability
- Flexible deployment across environments (Kubernetes, Docker)
- Secure secret management

## Prerequisites
- Docker
- Docker Compose
- For Cloudflare mode: Cloudflare Account and Cloudflare Tunnel
- For Tailscale mode: Tailscale account and auth key

## Configuration

### Environment Variables
Create a `.env` file with the following variables based on your chosen proxy mode:

#### Proxy Mode
```bash
# Proxy Mode: cloudflare, tailscale, or hybrid
PROXY_MODE=cloudflare

# HAProxy Toggle (optional, defaults to true)
HAPROXY_ENABLE=true
```

#### Cloudflare Configuration (required for PROXY_MODE=cloudflare or hybrid)
```bash
# Cloudflare Tunnel Configuration
ACCOUNT_TAG=your-account-tag
TUNNEL_ID=your-tunnel-id
TUNNEL_SECRET=your-tunnel-secret

# Service Mapping
CLOUDFLARE_HOSTNAMES=service1.example.com,service2.example.com
LOCAL_PORTS=8080,9090
TUNNEL_ROUTE_MODE=tcp  # Options: tcp, access
```

#### Tailscale Configuration (required for PROXY_MODE=tailscale or hybrid)
```bash
# Enable Tailscale
TAILSCALE_ENABLE=true
TAILSCALE_AUTHKEY=tskey-auth-xxxxxxxxxxxx

# Optional Tailscale Configuration
TAILSCALE_HOSTNAME=cloudflare-proxy  # Custom hostname for this node in Tailscale
TAILSCALE_ADVERTISE_ROUTES=10.0.0.0/24,192.168.1.0/24  # Routes to advertise to Tailscale network
TAILSCALE_ACCEPT_ROUTES=false  # Whether to accept routes advertised by other nodes
TAILSCALE_ACCEPT_DNS=false  # Whether to use Tailscale DNS
```

### Docker Requirements for Tailscale

**Important**: For Tailscale to work properly in the container, the following Docker configuration is required:

#### Required Capabilities and Privileges
The container needs elevated privileges to access the TUN interface:
- `NET_ADMIN` - Required for network administration
- `SYS_MODULE` - Required for kernel module operations  
- `NET_RAW` - Required for raw network access
- `privileged: true` - Required for full TUN device access

#### Device Mapping
The TUN device must be mapped into the container:
```yaml
devices:
  - /dev/net/tun:/dev/net/tun
volumes:
  - /dev/net/tun:/dev/net/tun
```

#### Host Requirements
Ensure the TUN module is loaded on your host system:
```bash
# Check if TUN module is loaded
lsmod | grep tun

# Load TUN module if not present
sudo modprobe tun

# Verify TUN device exists
ls -la /dev/net/tun
```

## Getting Started

### For Cloudflare Mode

#### Create a new Cloudflare Tunnel
```cloudflared tunnel create <tunnel-name>```

Grab the credentials and add them to the ```.env``` file.

### For Tailscale Mode

#### Generate a Tailscale Auth Key
1. Log in to the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Navigate to Settings > Keys
3. Generate a new auth key (reusable or one-time use)
4. Add the auth key to your `.env` file as `TAILSCALE_AUTHKEY`

### Build the Docker container
```docker-compose build```

### Deploy the Docker container
```docker-compose up -d```

### Updating Configuration

Configurations for cloudflared and haproxy are stored within the respective config directories.

Once you have updated the configurations, you can trigger a reload of the service with the following command, whilst inside the configuration directory for that service:

```touch .reload```

## Troubleshooting

### Tailscale Issues

#### Error: "CreateTUN failed; /dev/net/tun does not exist"
This indicates the container cannot access the TUN device. Ensure:

1. **Host has TUN support**:
   ```bash
   # Check if TUN module is loaded
   lsmod | grep tun
   
   # If not loaded, load it
   sudo modprobe tun
   
   # Make it persistent across reboots
   echo 'tun' | sudo tee -a /etc/modules
   ```

2. **Container has proper privileges**:
   ```yaml
   # In docker-compose.yml
   privileged: true
   cap_add:
     - NET_ADMIN
     - SYS_MODULE  
     - NET_RAW
   devices:
     - /dev/net/tun:/dev/net/tun
   ```

3. **Verify TUN device exists**:
   ```bash
   ls -la /dev/net/tun
   # Should show: crw-rw-rw- 1 root root 10, 200 <date> /dev/net/tun
   ```

#### Error: "netlink receive: operation not permitted"
This usually indicates insufficient container privileges. Ensure `privileged: true` is set in your Docker Compose configuration.

#### Error: "failed to connect to local tailscaled"
The Tailscale daemon may not be starting properly. Check:

1. **Container logs**:
   ```bash
   docker-compose logs -f tunnel-proxy
   ```

2. **Verify environment variables**:
   - `TAILSCALE_ENABLE=true`
   - `TAILSCALE_AUTHKEY` is set and valid
   - `PROXY_MODE=tailscale` or `PROXY_MODE=hybrid`

3. **Check if tailscaled process is running**:
   ```bash
   docker-compose exec tunnel-proxy pgrep tailscaled
   ```

### General Debugging

#### Check Container Health
```bash
# View container health status
docker-compose ps

# Check detailed logs
docker-compose logs -f tunnel-proxy

# Execute commands inside container
docker-compose exec tunnel-proxy bash
```

#### Verify Network Connectivity
```bash
# Test Tailscale connectivity (from inside container)
docker-compose exec tunnel-proxy tailscale status

# Test Cloudflare tunnel (from inside container)  
docker-compose exec tunnel-proxy cloudflared tunnel info $TUNNEL_ID
```

## Uses

### Global Load Balancer with Cloudflare

Cloudflare tunnels allow up to 25 tunnel replicas (which are effectively multiple tunnel instances for the same tunnel ID). 

Using this docker container, you can deploy multiple instances of the same endpoint in multiple locations. Cloudflare perform least-path routing to get you to the closest tunnel endpoint.

### Private Network Access with Tailscale

Using Tailscale mode, you can:
- Create a secure, private network between your services
- Access services without exposing them to the public internet
- Establish direct connections between nodes without complex VPN setup
- Use Tailscale's MagicDNS for easy service discovery

### Hybrid Connectivity

Using the hybrid mode (both Cloudflare and Tailscale), you can:
- Provide public access to services via Cloudflare tunnels
- Maintain a private, secure network between your infrastructure with Tailscale
- Have redundant connectivity options for high availability
- Choose the most appropriate access method for different services

### HAProxy Configuration

By default, HAProxy is enabled to provide load balancing capabilities. You can disable HAProxy if you don't need load balancing or if you're using another load balancing solution:

```bash
# Disable HAProxy
HAPROXY_ENABLE=false
```

Use cases for disabling HAProxy:
- Direct connections to a single backend service
- When using external load balancing (e.g., Kubernetes services)
- Simplified setup for testing or development environments
- When using Tailscale's built-in routing capabilities without additional load balancing
