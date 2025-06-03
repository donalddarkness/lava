#!/usr/bin/env bash
# Bash script to fully clean and rebuild the Lava workspace on Unix/WSL
# Usage: ./clean-build.sh

set -euo pipefail

echo "[Lava] Killing Swift and SourceKit processes..."
pkill -f swiftc || true
pkill -f swift || true
pkill -f sourcekit-lsp || true

echo "[Lava] Removing workspace .build directory..."
rm -rf .build

echo "[Lava] Clearing global SwiftPM cache..."
rm -rf ~/.swiftpm

echo "[Lava] Rebuilding project in debug configuration..."
swift build -c debug

echo "[Lava] Build complete." 