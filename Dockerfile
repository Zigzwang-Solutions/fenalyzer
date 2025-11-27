# --- Stage 1: Build ---
# Use a specific Zig version compatible with the source code (v0.11 - v0.13)
FROM ziglang/zig:0.13.0 as builder

WORKDIR /app

# Copy only the necessary source code
COPY fen_parser.zig .

# Compile the static binary (ReleaseSafe mode)
# -femit-bin=fen_parser ensures a consistent output filename
RUN zig build-exe fen_parser.zig -O ReleaseSafe -femit-bin=fen_parser

# --- Stage 2: Run ---
# Use a minimal Alpine Linux image for the final production container
FROM alpine:latest

WORKDIR /app

# Copy ONLY the executable from the builder stage
COPY --from=builder /app/fen_parser .

# Set the binary as the entrypoint
ENTRYPOINT ["./fen_parser"]