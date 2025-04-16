FROM alpine:latest

# Install dependencies
RUN apk add --no-cache wget ca-certificates bash

# Download and install cloudflared
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    && chmod +x cloudflared-linux-amd64 \
    && mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

WORKDIR /app

COPY create_tunnel.sh /app/create_tunnel.sh
RUN chmod +x /app/create_tunnel.sh

ENTRYPOINT ["/bin/bash", "/app/create_tunnel.sh"]

