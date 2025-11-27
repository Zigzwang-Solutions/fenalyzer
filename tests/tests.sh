#!/bin/bash

# tests/tests.sh - Automated Integration Testing Suite (Linux/macOS)

# PATH FIX: Point to the binary in the parent (root) directory
BINARY="../fen_parser"

# Output Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 1. Check Prerequisites
if [ ! -f "$BINARY" ]; then
    echo -e "${RED}[ERROR] Binary not found at $BINARY. Please run './build.sh' in the root directory first.${NC}"
    exit 1
fi

echo -e "${CYAN}\n=== STARTING INTEGRATION TESTS ===\n${NC}"

PASSED=0
TOTAL=0

# Helper function to run a test case
run_test() {
    local fen="$1"
    local expected="$2" # "true" or "false"
    
    ((TOTAL++))
    echo -n "Test #$TOTAL... "
    
    # Run binary and capture output
    output=$($BINARY "$fen")
    
    # Check result using grep to parse the JSON boolean validity
    if echo "$output" | grep -q "\"valid\": $expected"; then
        echo -e "${GREEN}[PASS]${NC}"
        ((PASSED++))
    else
        echo -e "${RED}[FAIL]${NC}"
        echo "   Input: $fen"
        echo "   Expected: $expected"
        echo "   Got Output: $output"
    fi
}

# --- 2. Define Test Cases ---

# Valid Cases
run_test "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" "true"
run_test "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1" "true"
run_test "8/8/8/8/8/8/8/4K2k w - - 0 1" "true"

# Invalid Cases
run_test "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR" "false"               # Missing fields
run_test "pppppppp/8/8/8/8/8/8/8 w - - 0 1" "false"                           # Pawns on backrank
run_test "8/8/8/8/8/8/8/8 w - - 0 1" "false"                                  # Missing Kings
run_test "rnbqkbnr/pppppppp/9/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" "false"  # Invalid geometry

# --- 3. Summary ---
echo -e "${CYAN}\n=== SUMMARY ===${NC}"
if [ $PASSED -eq $TOTAL ]; then
    echo -e "${GREEN}All $TOTAL tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$((TOTAL - PASSED)) tests failed.${NC}"
    exit 1
fi