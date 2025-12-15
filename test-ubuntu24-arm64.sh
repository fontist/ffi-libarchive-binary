#!/bin/bash
set -e

# Allow skipping the clean step via CLEAN=0 environment variable
if [ "${CLEAN:-1}" = "1" ]; then
  echo "===== Cleaning local build cache ====="
  rm -rf tmp ports pkg lib/ffi-libarchive-binary/libarchive.*
  echo "Local build cache cleaned"
else
  echo "===== Skipping clean (using cached builds) ====="
fi
echo ""

echo "===== Building Docker image for Ubuntu 24.04 ARM64 testing ====="
echo ""

# Build the Docker image with caching
docker build \
  --platform linux/arm64 \
  --network=host \
  -f Dockerfile.ubuntu24-arm64 \
  -t ffi-libarchive-test:ubuntu24-arm64 \
  .

echo ""
echo "===== Running tests in Docker container ====="
echo ""

# Create Docker volumes for caching if they don't exist
docker volume create ffi-libarchive-tmp 2>/dev/null || true
docker volume create ffi-libarchive-ports 2>/dev/null || true

# Run the tests with volume mounts for caching
docker run --rm \
  --platform linux/arm64 \
  --network=host \
  -v "$(pwd):/workspace" \
  -v ffi-libarchive-tmp:/workspace/tmp \
  -v ffi-libarchive-ports:/workspace/ports \
  ffi-libarchive-test:ubuntu24-arm64

echo ""
echo "===== Docker test completed ====="
echo ""
echo "Tip: To rebuild from scratch, run: CLEAN=1 $0"
echo "     To use cached builds, run: CLEAN=0 $0"