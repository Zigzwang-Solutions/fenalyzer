#!/usr/bin/env bash

# Shell Best Practices: Strict Mode
# Fail fast on errors, unset variables, or pipe failures.
set -o errexit
set -o nounset
set -o pipefail

# Configuration
ZIG_SOURCE="fen_parser.zig"
BINARY_NAME="fen_parser"
CACHE_DIR="./zig-cache"
WEB_INDEX="web/index.html"

# Logging Utilities
log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }
log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }

usage() {
    echo "Usage: $0 [options] \"<fen_string>\""
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -r, --rebuild Force recompilation of the Zig binary"
    echo "  -w, --web     Open the FEN in the web viewer (default browser)"
    echo ""
    echo "Example:"
    echo "  $0 -w \"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1\""
}

check_dependencies() {
    if ! command -v zig &> /dev/null; then
        log_error "Zig compiler not found in PATH."
        exit 1
    fi
}

compile_zig() {
    local force=${1:-0}
    # Check if binary exists or rebuild is forced
    if [[ ! -f "$BINARY_NAME" ]] || [[ "$force" -eq 1 ]]; then
        log_info "Compiling $ZIG_SOURCE (ReleaseSafe)..."
        if zig build-exe "$ZIG_SOURCE" -O ReleaseSafe -femit-bin="$BINARY_NAME" --cache-dir "$CACHE_DIR"; then
            log_success "Compilation finished successfully."
        else
            log_error "Compilation failed."
            exit 1
        fi
    fi
}

open_url() {
    local url="$1"
    if command -v xdg-open &> /dev/null; then
        xdg-open "$url"
    elif command -v open &> /dev/null; then
        open "$url"
    else
        log_info "Could not detect browser opener. Open this URL manually:"
        echo "$url"
    fi
}

main() {
    local rebuild=0
    local open_web=0
    local fen_input=""

    # Argument Parsing
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) usage; exit 0 ;;
            -r|--rebuild) rebuild=1; shift ;;
            -w|--web) open_web=1; shift ;;
            -*) log_error "Unknown option: $1"; usage; exit 1 ;;
            *)
                if [[ -z "$fen_input" ]]; then
                    fen_input="$1"
                else
                    log_error "Only one FEN string allowed."
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$fen_input" ]]; then
        log_error "No FEN string provided."
        usage; exit 1
    fi

    check_dependencies
    compile_zig "$rebuild"

    log_info "Analyzing FEN..."
    if output=$(./"$BINARY_NAME" "$fen_input"); then
        # Pretty print JSON if 'jq' is available
        if command -v jq &> /dev/null; then
            echo "$output" | jq .
        else
            echo "$output"
        fi

        # Web Viewer Integration
        if [[ "$open_web" -eq 1 ]]; then
            # Safe URL Encoding using Python if available
            local encoded_fen
            if command -v python3 &> /dev/null; then
                encoded_fen=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$fen_input")
            else
                # Simple fallback (replaces spaces with %20)
                encoded_fen="${fen_input// /%20}"
            fi

            # Resolve absolute path for browser
            local abs_path
            # MacOS/Linux realpath difference handling
            if command -v realpath &> /dev/null; then
                abs_path=$(realpath "$WEB_INDEX")
            else
                abs_path="$(cd "$(dirname "$WEB_INDEX")"; pwd)/$(basename "$WEB_INDEX")"
            fi

            local url="file://$abs_path?fen=$encoded_fen"
            log_info "Opening web viewer..."
            open_url "$url"
        fi
    else
        exit_code=$?
        log_error "Validation process failed (Exit Code: $exit_code)"
        exit $exit_code
    fi
}

main "$@"