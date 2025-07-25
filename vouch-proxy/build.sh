#!/bin/bash

# Build script for vouch-proxy Docker image
# Supports local testing and multi-architecture builds

set -e

# Default values
VOUCH_VERSION="latest"
IMAGE_TAG="vouch-proxy"
PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
PUSH=false
REGISTRY=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VOUCH_VERSION="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        -r|--registry)
            REGISTRY="$2/"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --version VERSION    Vouch-proxy version to build (default: latest)"
            echo "  -t, --tag TAG           Docker image tag (default: vouch-proxy)"
            echo "  -p, --platforms PLATFORMS  Target platforms (default: linux/amd64,linux/arm64,linux/arm/v7)"
            echo "  --push                  Push image to registry"
            echo "  -r, --registry REGISTRY Registry prefix (e.g., username for DockerHub)"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Build latest for all platforms"
            echo "  $0 -v v0.37.3 -t vouch-proxy:v0.37.3 # Build specific version"
            echo "  $0 --push -r myusername               # Build and push to DockerHub"
            echo "  $0 -p linux/arm64                    # Build only for ARM64"
            echo "  $0 -p linux/arm/v7                   # Build only for ARMv7"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Full image name
FULL_IMAGE_TAG="${REGISTRY}${IMAGE_TAG}"

echo "Building vouch-proxy Docker image..."
echo "  Vouch version: $VOUCH_VERSION"
echo "  Image tag: $FULL_IMAGE_TAG"
echo "  Platforms: $PLATFORMS"
echo "  Push: $PUSH"
echo ""

# Check if buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: Docker buildx is required for multi-platform builds"
    echo "Please install Docker Desktop or enable buildx"
    exit 1
fi

# Create builder if it doesn't exist
if ! docker buildx inspect multiarch >/dev/null 2>&1; then
    echo "Creating buildx builder..."
    docker buildx create --name multiarch --driver docker-container --use
fi

# Use the multiarch builder
docker buildx use multiarch

# Build command
BUILD_CMD="docker buildx build"
BUILD_CMD="$BUILD_CMD --platform $PLATFORMS"
BUILD_CMD="$BUILD_CMD --build-arg VOUCH_VERSION=$VOUCH_VERSION"
BUILD_CMD="$BUILD_CMD --tag $FULL_IMAGE_TAG"

if [ "$PUSH" = true ]; then
    BUILD_CMD="$BUILD_CMD --push"
else
    BUILD_CMD="$BUILD_CMD --load"
fi

BUILD_CMD="$BUILD_CMD ."

echo "Executing: $BUILD_CMD"
echo ""

# Execute the build
eval $BUILD_CMD

echo ""
echo "Build completed successfully!"

if [ "$PUSH" = false ]; then
    echo "Image built locally as: $FULL_IMAGE_TAG"
    echo "To test the image:"
    echo "  docker run --rm -p 9090:9090 $FULL_IMAGE_TAG"
else
    echo "Image pushed to registry as: $FULL_IMAGE_TAG"
fi