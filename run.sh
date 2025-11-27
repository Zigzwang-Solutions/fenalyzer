#!/bin/bash

# Configuration
BINARY="./fen_parser"
WEB_INDEX="web/index.html"
FEN_INPUT=""
WEB_MODE=false

# Colors
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -w|-W|--web) WEB_MODE=true ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
        *) FEN_INPUT="$1" ;;
    esac
    shift
done

# 1. Check if binary exists
if [ ! -f "$BINARY" ]; then
    echo -e "${RED}[ERROR] Binary not found!${NC}"
    echo -e "${YELLOW}Please run './build.sh' first to create the executable.${NC}"
    exit 1
fi

# 2. Validate input
if [ -z "$FEN_INPUT" ]; then
    echo -e "${RED}[ERROR] No FEN string provided.${NC}"
    echo "Usage: ./run.sh [-w] \"<fen_string>\""
    exit 1
fi

# 3. Execute validation
OUTPUT=$($BINARY "$FEN_INPUT")
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo -e "${RED}[ERROR] Execution failed.${NC}"
    echo "$OUTPUT"
    exit $EXIT_CODE
fi

# Pretty print JSON if jq is available
if command -v jq &> /dev/null; then
    echo "$OUTPUT" | jq .
else
    echo "$OUTPUT"
fi

# 4. Web Integration
if [ "$WEB_MODE" = true ]; then
    if [ ! -f "$WEB_INDEX" ]; then
        echo -e "${RED}[ERROR] File web/index.html not found.${NC}"
        exit 1
    fi

    echo -e "${CYAN}Preparing web viewer...${NC}"

    # Use Python3 for safe URL Encoding
    if command -v python3 &> /dev/null; then
        ENCODED_FEN=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$FEN_INPUT'''))")
    else
        echo -e "${YELLOW}[WARN] Python3 not found. URL encoding might fail for complex FENs.${NC}"
        ENCODED_FEN="$FEN_INPUT"
    fi

    # Resolve absolute path (Cross-platform)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ABS_PATH=$(perl -e 'use Cwd "abs_path"; print abs_path(@ARGV[0])' -- "$WEB_INDEX")
    else
        ABS_PATH=$(readlink -f "$WEB_INDEX")
    fi

    FINAL_URL="file://$ABS_PATH?fen=$ENCODED_FEN"

    echo -e "${CYAN}Opening default browser...${NC}"
    
    # Launch browser
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$FINAL_URL"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$FINAL_URL"
    else
        echo -e "${YELLOW}Could not detect browser launcher. Open this link manually:${NC}"
        echo "$FINAL_URL"
    fi
fi