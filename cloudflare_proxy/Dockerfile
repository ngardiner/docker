FROM alpine:3.18

# Install necessary packages
RUN apk add --no-cache \
    haproxy \
    bash \
    curl \
    jq \
    procps \
    iptables \
    ca-certificates

# Download Cloudflared binary
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64) CLOUDFLARED_ARCH=amd64 ;; \
      aarch64) CLOUDFLARED_ARCH=arm64 ;; \
      *) echo "Unsupported architecture" && exit 1 ;; \
    esac && \
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CLOUDFLARED_ARCH} -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# Download Tailscale binary
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64) TAILSCALE_ARCH=amd64 ;; \
      aarch64) TAILSCALE_ARCH=arm64 ;; \
      *) echo "Unsupported architecture" && exit 1 ;; \
    esac && \
    curl -fsSL https://pkgs.tailscale.com/stable/tailscale_latest_linux_${TAILSCALE_ARCH}.tgz | tar xzf - --strip-components=1 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/tailscale /usr/local/bin/tailscaled

# Create necessary directories
RUN mkdir -p /etc/cloudflared /etc/haproxy /app /var/lib/tailscale

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

# Tailscale environment variables
ENV TAILSCALE_AUTHKEY=""
ENV TAILSCALE_HOSTNAME=""
ENV TAILSCALE_ADVERTISE_ROUTES=""
ENV TAILSCALE_ACCEPT_ROUTES="false"
ENV TAILSCALE_ACCEPT_DNS="false"
ENV TAILSCALE_ENABLE="false"
ENV PROXY_MODE="cloudflare"

# HAProxy toggle
ENV HAPROXY_ENABLE="true"

# Default entrypoint
ENTRYPOINT ["/entrypoint.sh"]
