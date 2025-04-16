FROM alpine:3.18

# Install necessary packages
RUN apk add --no-cache \
    haproxy \
    bash \
    curl \
    jq \
    procps

# Download Cloudflared binary
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64) CLOUDFLARED_ARCH=amd64 ;; \
      aarch64) CLOUDFLARED_ARCH=arm64 ;; \
      *) echo "Unsupported architecture" && exit 1 ;; \
    esac && \
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CLOUDFLARED_ARCH} -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# Create necessary directories
RUN mkdir -p /etc/cloudflared /etc/haproxy /app

# Copy scripts and configs
COPY tunnel-manager.sh /app/tunnel-manager.sh
COPY entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /app/tunnel-manager.sh /entrypoint.sh

# Environment variables for configuration
ENV ACCOUNT_TAG=""
ENV TUNNEL_ID=""
ENV TUNNEL_SECRET=""
ENV CLOUDFLARE_HOSTNAMES=""
ENV LOCAL_PORTS=""
ENV TUNNEL_ROUTE_MODE="tcp"

# Default entrypoint
ENTRYPOINT ["/entrypoint.sh"]
