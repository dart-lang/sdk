# Simple Dockerfile for the Hytopia server (Dart)
FROM dart:stable

WORKDIR /app

# Copy repository files (keep context small when building)
COPY . /app

# Ensure dependencies (no-op if none)
RUN dart pub get || true

# Expose default port (can be overridden via HYTOPIA_PORT)
EXPOSE 8080

# Default command
CMD ["dart", "run", "tools/hytopia_server/bin/server.dart"]
