# Hytopia server

Minimal Dart HTTP server for Hytopia.

Run:

```bash
# From workspace root
dart run tools/hytopia_server/bin/server.dart
```

Environment:

- `HYTOPIA_PORT` — override default port (8080)

Endpoints:

- `GET /` — serves a small HTML page
- `GET /health` — returns `{ "status": "ok" }`
- `POST /echo` — echoes submitted JSON as `{ "echo": ... }`
- `GET /static/<path>` — serves files from `tools/hytopia_server/public`

Next steps (optional): Dockerfile, systemd unit, or integrate into your deployment.
