#!/bin/bash

# tests/docker_tests.sh - Automated Docker Container Testing Suite

IMAGE_NAME="fenalyzer:test"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}\n=== STARTING DOCKER TESTS ===\n${NC}"

# 1. Build Test
# PATH FIX: Build context is '..' (parent directory) to find the Dockerfile in root
echo -n "Test #1: Building Image from parent context... "
if docker build -t "$IMAGE_NAME" .. > /dev/null 2>&1; then
    echo -e "${GREEN}[PASS]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    echo "Docker build failed."
    exit 1
fi

# 2. Security Test (Non-root User)
echo -n "Test #2: Checking Non-root User... "
USER_OUTPUT=$(docker run --rm --entrypoint whoami "$IMAGE_NAME")
# Remove whitespace/newlines
USER_OUTPUT=$(echo "$USER_OUTPUT" | tr -d '[:space:]')

if [ "$USER_OUTPUT" = "appuser" ]; then
    echo -e "${GREEN}[PASS]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    echo "   Expected: appuser"
    echo "   Got: $USER_OUTPUT"
fi

# 3. Logic Integration Test
echo -n "Test #3: Verifying FEN Parsing Logic... "
TEST_FEN="rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
JSON_OUTPUT=$(docker run --rm "$IMAGE_NAME" "$TEST_FEN")

# Check if JSON contains "valid": true
if echo "$JSON_OUTPUT" | grep -q '"valid": true'; then
    echo -e "${GREEN}[PASS]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    echo "   Container output invalid: $JSON_OUTPUT"
fi

# 4. Cleanup
echo -e "${CYAN}Cleaning up...${NC}"
docker rmi "$IMAGE_NAME" > /dev/null 2>&1

echo -e "${GREEN}Docker tests completed successfully.${NC}"