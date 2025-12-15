#!/bin/bash

# Diagnostic script to check libarchive format and codec support

echo "===== Checking libarchive library features ====="
echo ""

LIB_PATH="lib/ffi-libarchive-binary/libarchive.so"

if [ ! -f "$LIB_PATH" ]; then
    echo "ERROR: libarchive library not found at $LIB_PATH"
    exit 1
fi

echo "Library file: $LIB_PATH"
echo ""

echo "===== File info ====="
file "$LIB_PATH"
echo ""

echo "===== Library size ====="
ls -lh "$LIB_PATH"
echo ""

echo "===== Checking for format support symbols ====="
echo "XAR format symbols:"
nm -D "$LIB_PATH" 2>/dev/null | grep -i xar | head -20 || echo "  No XAR symbols found"
echo ""

echo "===== Checking for codec support symbols ====="
echo "LZMA codec symbols:"
nm -D "$LIB_PATH" 2>/dev/null | grep -i lzma | head -20 || echo "  No LZMA symbols found"
echo ""

echo "===== Checking library dependencies ====="
ldd "$LIB_PATH" 2>/dev/null || readelf -d "$LIB_PATH" 2>/dev/null | grep NEEDED || echo "  Cannot read dependencies"
echo ""

echo "===== Checking for statically linked libraries ====="
strings "$LIB_PATH" | grep -i "liblzma\|lzma" | head -10 || echo "  No LZMA strings found"
echo ""

echo "===== Checking built XZ library ====="
find tmp -name "liblzma.*" -type f 2>/dev/null | while read xz_lib; do
    echo "Found: $xz_lib"
    file "$xz_lib"
done
echo ""

echo "===== Checking for libarchive configuration ====="
strings "$LIB_PATH" | grep -E "archive_version|ARCHIVE" | head -10
echo ""

echo "===== Done ====="