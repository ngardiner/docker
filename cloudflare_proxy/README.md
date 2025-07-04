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
