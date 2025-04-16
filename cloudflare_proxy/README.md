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

## Getting Started

### Create a new Cloudflare Tunnel
```cloudflared tunnel create <tunnel-name>```

Grab the credentials and 

### Deploy the Docker container
```docker-compose up -d```

