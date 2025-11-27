#!/bin/bash
# scripts/build.sh - Compiles the Zig project (Unix)

set -e # Exit on error

# --- Path Configuration ---
ZIG_SOURCE="../fen_parser.zig"
BINARY_NAME="../fen_parser"
CACHE_DIR="../zig-cache"

# Output colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}[BUILD] Starting Zig compilation (ReleaseSafe)...${NC}"

# 1. Check if Zig is installed
if ! command -v zig &> /dev/null; then
    echo -e "${RED}[ERROR] Zig compiler not found in PATH.${NC}"
    exit 1
fi

# 2. Compile
zig build-exe "$ZIG_SOURCE" -O ReleaseSafe -femit-bin="$BINARY_NAME" --cache-dir "$CACHE_DIR"

echo -e "${GREEN}[SUCCESS] Compilation finished successfully: $BINARY_NAME${NC}"