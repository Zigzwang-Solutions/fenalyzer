# --- Stage 1: Build ---
FROM ziglang/zig:0.13.0 as builder

WORKDIR /app
COPY fen_parser.zig .
RUN zig build-exe fen_parser.zig -O ReleaseSafe -femit-bin=fen_parser

# --- Stage 2: Run ---
FROM alpine:latest

# SECURITY: Create a non-root user
RUN adduser -D appuser

WORKDIR /app

# Copy binary
COPY --from=builder /app/fen_parser .

# Change ownership to non-root user
RUN chown appuser:appuser /app/fen_parser

# Switch to non-root user
USER appuser

ENTRYPOINT ["./fen_parser"]