# --- Stage 1: Build ---
# Uses a specific Zig version to ensure reproducibility
FROM ziglang/zig:0.13.0 as builder

WORKDIR /app

# Copy source code from the project root
COPY fen_parser.zig .

# Compile the static binary (ReleaseSafe mode)
# -femit-bin=fen_parser ensures the output filename is consistent
RUN zig build-exe fen_parser.zig -O ReleaseSafe -femit-bin=fen_parser

# --- Stage 2: Runtime ---
# Uses a minimal Alpine Linux image for production
FROM alpine:latest

# SECURITY: Create a non-root user to run the application
RUN adduser -D appuser

WORKDIR /app

# Copy ONLY the executable from the builder stage
COPY --from=builder /app/fen_parser .

# Change ownership of the binary to the non-root user
RUN chown appuser:appuser /app/fen_parser

# Switch context to non-root user
USER appuser

# Set the entrypoint
ENTRYPOINT ["./fen_parser"]