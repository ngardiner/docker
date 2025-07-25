# Multi-stage build for vouch-proxy with ARM support
FROM --platform=$BUILDPLATFORM golang:1.23-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /build

# Clone the vouch-proxy repository
ARG VOUCH_VERSION=latest
RUN if [ "$VOUCH_VERSION" = "latest" ]; then \
        git clone https://github.com/vouch/vouch-proxy.git . ; \
    else \
        git clone --branch $VOUCH_VERSION https://github.com/vouch/vouch-proxy.git . ; \
    fi

# Build the binary for the target architecture
ENV CGO_ENABLED=0
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH
ENV GOARM=${TARGETVARIANT#v}

RUN go mod download && \
    go build -ldflags="-w -s" -o vouch-proxy

# Create a minimal user for security
RUN echo "vouch:x:1000:1000:vouch:/:/sbin/nologin" > /tmp/passwd && \
    echo "vouch:x:1000:" > /tmp/group

# Final stage - minimal runtime image
FROM scratch

LABEL maintainer="vouch@bnf.net"
LABEL description="Vouch Proxy - An SSO and OAuth / OIDC login solution"
LABEL org.opencontainers.image.source="https://github.com/vouch/vouch-proxy"

# Copy CA certificates for HTTPS requests
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Copy user and group files
COPY --from=builder /tmp/passwd /etc/passwd
COPY --from=builder /tmp/group /etc/group

# Copy the binary
COPY --from=builder /build/vouch-proxy /vouch-proxy

# Use non-root user
USER vouch

# Expose the default port
EXPOSE 9090

# Set the entrypoint
ENTRYPOINT ["/vouch-proxy"]

# Add healthcheck
HEALTHCHECK --interval=1m --timeout=3s --start-period=5s --retries=3 \
    CMD ["/vouch-proxy", "-healthcheck"]