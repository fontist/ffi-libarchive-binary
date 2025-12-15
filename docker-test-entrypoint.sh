#!/bin/bash
set -e

echo "===== Testing ffi-libarchive-binary on Ubuntu 24.04 ARM64 ====="
echo "Platform: ${PLATFORM}"
echo "Ruby: $(ruby --version)"
echo ""

echo "===== Cleaning previous build artifacts ====="
# Clean pkg and libarchive binaries, but NOT tmp/ports if they're mounted volumes
rm -rf pkg lib/ffi-libarchive-binary/libarchive.*
# Only clean tmp/ports contents if not mounted (mountpoint will fail if not mounted)
if ! mountpoint -q tmp 2>/dev/null; then
  rm -rf tmp
fi
if ! mountpoint -q ports 2>/dev/null; then
  rm -rf ports
fi
echo "Build cache cleaned"
echo ""

echo "===== Checking liblzma availability ====="
dpkg -L liblzma-dev | grep -E '\.a$|\.so' | head -10 || echo 'No liblzma libraries found'
echo ""

echo "===== Building native gem ====="
bundle exec rake gem:native:${PLATFORM}
echo ""

echo "===== Checking where XZ was installed ====="
find ports tmp -name "liblzma.a" -o -name "liblzma.so*" 2>/dev/null || echo "No liblzma library files found"
echo ""

echo "===== Checking XZ recipe install path ====="
find ports -type d -name "xz" 2>/dev/null || echo "No XZ ports directory"
ls -la ports/aarch64-linux-gnu/xz/*/lib/ 2>/dev/null || echo "No lib directory in XZ install"
echo ""

echo "===== Checking libarchive CMake config ====="
find tmp -name "CMakeCache.txt" -path "*/libarchive/*" -exec grep -i "lzma\|xz" {} \; 2>/dev/null | head -20 || echo "No CMake cache found"
echo ""

echo "===== Checking built libraries ====="
find lib/ffi-libarchive-binary -name 'libarchive.*' -type f
echo ""

if [ -f lib/ffi-libarchive-binary/libarchive.so ]; then
  echo "===== Library file info ====="
  file lib/ffi-libarchive-binary/libarchive.so
  echo ""

  echo "===== Library dependencies (readelf) ====="
  readelf -d lib/ffi-libarchive-binary/libarchive.so | grep NEEDED || echo 'No NEEDED entries'
  echo ""

  echo "===== Library symbols - XAR format ====="
  nm -D lib/ffi-libarchive-binary/libarchive.so 2>/dev/null | grep -i 'xar\|archive_read_support_format_xar' | head -10 || echo 'No XAR symbols found'
  echo ""

  echo "===== Library symbols - LZMA codec ====="
  nm -D lib/ffi-libarchive-binary/libarchive.so 2>/dev/null | grep -i 'lzma\|archive.*lzma' | head -10 || echo 'No LZMA symbols found'
  echo ""

  echo "===== Checking for liblzma linkage ====="
  readelf -d lib/ffi-libarchive-binary/libarchive.so | grep -i lzma || echo 'No liblzma in dependencies'
  strings lib/ffi-libarchive-binary/libarchive.so | grep -i 'liblzma\|LZMA' | head -10 || echo 'No LZMA strings found'
  echo ""

  echo "===== Checking for lzma_ symbols (from liblzma) ====="
  nm lib/ffi-libarchive-binary/libarchive.so 2>/dev/null | grep " lzma_" | head -10 || echo 'No lzma_ symbols found'
  echo ""

  echo "===== Checking for libxml2 linkage ====="
  readelf -d lib/ffi-libarchive-binary/libarchive.so | grep -i xml || echo 'No libxml2 in dependencies'
  echo ""

  echo "===== Checking for xml symbols (from libxml2) ====="
  nm lib/ffi-libarchive-binary/libarchive.so 2>/dev/null | grep " xml" | head -20 || echo 'No xml symbols found'
  echo ""
fi

echo "===== Checking libarchive CMake configuration for libxml2 ====="
find tmp -name "CMakeCache.txt" -path "*/libarchive/*" -exec grep -i "libxml2\|HAVE_LIBXML" {} \; 2>/dev/null | head -30 || echo "No CMake cache found"
echo ""

echo "===== Running tests ====="
bundle exec rspec -fd
echo ""

echo "===== Test completed ====="