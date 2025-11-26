# Stage 1: Builder
# We use Alpine to download and compile the Zig binary
FROM alpine:latest AS builder

# Install dependencies for downloading and extracting Zig
RUN apk add --no-cache curl xz tar

# Set Zig version (ensuring reproducibility)
# You can update this version as needed
ARG ZIG_VERSION=0.13.0
ARG ARCH=x86_64-linux

# Download and install Zig
WORKDIR /usr/local/bin
RUN curl -L "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz" | tar -xJ \
    && mv zig-linux-${ARCH}-${ZIG_VERSION}/* . \
    && rm -rf zig-linux-${ARCH}-${ZIG_VERSION}

# Setup application directory
WORKDIR /app
COPY fen_parser.zig .

# Compile static binary
# -O ReleaseSafe: Optimizations on, but keeping safety checks (overflows, bounds)
# -target x86_64-linux-musl: Ensures a static binary compatible with Alpine
RUN zig build-exe fen_parser.zig -O ReleaseSafe -target x86_64-linux-musl

# Stage 2: Runtime
# Minimalist image for production
FROM alpine:latest

# Create a non-root user for security (best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder /app/fen_parser .

# Set permissions and user
RUN chown appuser:appgroup fen_parser
USER appuser

# Entrypoint configuration
ENTRYPOINT ["./fen_parser"]
CMD ["-h"]