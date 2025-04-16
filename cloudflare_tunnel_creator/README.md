# Cloudflare Tunnel Creator

## Overview

This Docker container provides a simple, streamlined method for creating Cloudflare tunnels with minimal configuration and complexity.

## Prerequisites

- Docker installed
- Cloudflare account
- Active internet connection

## Features

- Interactive Cloudflare login
- Simple tunnel creation
- Credential output

## Usage

### Build the Image

```bash
docker build -t cloudflare-tunnel-creator .

docker run -it --rm \
    -e TUNNEL_NAME=my-test-tunnel \
    cloudflare-tunnel-creator
```
