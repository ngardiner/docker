# Cloudflared Tunnel Proxy Container

## Overview
This Docker container provides a flexible, multi-purpose Cloudflare tunnel proxy with HAProxy load balancing.

## Features
- Modular Cloudflare tunnel proxy support
- Dynamic access tunnel configuration to allow mapping of Cloudflare Tunnels to local ports
- HAProxy load balancing for High Availability
- Flexible deployment across environments (Kubernetes, Docker)
- Secure secret management

## Prerequisites
- Docker
- Docker Compose
- Cloudflare Account
- Cloudflare Tunnel

## Configuration

### Environment Variables
Create a `.env` file with the following variables:

```bash
# Tunnel Configuration
TUNNEL_HOSTNAME=your-tunnel-id
TUNNEL_SECRET=your-tunnel-secret

# Service Mapping
CLOUDFLARE_HOSTNAMES=service1.example.com,service2.example.com
LOCAL_PORTS=8080,9090
TUNNEL_ROUTE_MODE=tcp  # Options: tcp, access
```

## Getting Started

### Create a new Cloudflare Tunnel
```cloudflared tunnel create <tunnel-name>```

Grab the credentials and add them to the ```.env``` file.

### Build the Docker container
```docker-compose build```

### Deploy the Docker container
```docker-compose up -d```

### Updating Configuration

Configurations for cloudflared and haproxy are stored within the respective config directories.

Once you have updated the configurations, you can trigger a reload of the service with the following command, whilst inside the configuration directory for that service:

```touch .reload```

## Uses

### Global Load Balancer

Cloudflare tunnels allow up to 25 tunnel replicas (which are effectively multiple tunnel instances for the same tunnel ID). 

Using this docker container, you can deploy multiple instances of the same endpoint in multiple locations. Cloudflare perform least-path routing to get you to the closest tunnel endpoint.
