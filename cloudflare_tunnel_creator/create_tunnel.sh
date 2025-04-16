#!/bin/bash

# Check if tunnel name is provided
if [ -z "$TUNNEL_NAME" ]; then
	    echo "Error: TUNNEL_NAME environment variable must be set"
	        exit 1
fi

# Perform Cloudflare login
cloudflared login

# Create tunnel with provided name and capture output
OUTPUT=$(cloudflared tunnel create "$TUNNEL_NAME" 2>&1)

# Check if tunnel creation was successful
if [ $? -ne 0 ]; then
	    echo "Tunnel creation failed:"
	        echo "$OUTPUT"
		    exit 1
fi

# Find the credentials file
CRED_FILE=$(find /root/.cloudflared -name "*.json")

# Check if credentials file exists
if [ -z "$CRED_FILE" ]; then
	    echo "Credentials file not found"
	        exit 1
fi

# Output tunnel details
echo "Tunnel created with name: $TUNNEL_NAME"
echo "Credentials file found at: $CRED_FILE"
cat "$CRED_FILE"

