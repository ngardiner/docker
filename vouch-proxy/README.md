# Vouch Proxy Docker Image

This directory contains the infrastructure to build ARM-compatible Docker images for [vouch-proxy](https://github.com/vouch/vouch-proxy).

## Overview

Vouch Proxy is an SSO and OAuth / OIDC login solution that can be used to secure web applications. This Docker image is built to support both AMD64 and ARM64 architectures.

## Features

- Multi-architecture support (AMD64, ARM64, ARMv7)
- Minimal scratch-based image for security and size
- Non-root user execution
- Health check included
- Automatic versioning based on vouch-proxy releases

## Building

The image is automatically built and published via CI/CD when:
- Code is pushed to the main branch
- Tags are created (for versioned releases)

### CI/CD Platforms
- **GitHub Actions**: `.github/workflows/docker-build-vouch-proxy.yml`
- **GitLab CI**: `.gitlab-ci.yml`

Both platforms build identical multi-architecture images.

### Manual Build

To build manually:

```bash
# Build for current platform
docker build -t vouch-proxy .

# Build for specific platform
docker buildx build --platform linux/arm64 -t vouch-proxy:arm64 .
docker buildx build --platform linux/arm/v7 -t vouch-proxy:armv7 .
```

### Build Arguments

- `VOUCH_VERSION`: Specify a specific version/tag of vouch-proxy to build (default: latest)

Example:
```bash
docker build --build-arg VOUCH_VERSION=v0.37.3 -t vouch-proxy:v0.37.3 .
```

## Usage

```bash
# Run with default configuration
docker run -p 9090:9090 vouch-proxy

# Run with custom config
docker run -p 9090:9090 -v /path/to/config:/config vouch-proxy -config /config/config.yml
```

## Configuration

Vouch Proxy can be configured via:
- Configuration file (YAML)
- Environment variables
- Command line arguments

See the [official documentation](https://github.com/vouch/vouch-proxy) for detailed configuration options.