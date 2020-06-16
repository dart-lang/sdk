# 1.2.1

- Fixed issue where `evaluate` and `evaluateInFrame` were not invoking client
  provided implementations of `compileExpression`.

# 1.2.0

- Fixed issue where forwarding requests with no RPC parameters would return an
  RPC error.

# 1.1.0

- Added `getDartDevelopmentServiceVersion` RPC.
- Added DDS protocol to VM service `getSupportedProtocols` response.
- Added example/example.dart.
- Allow for JSON-RPC 2.0 requests which are missing the `jsonrpc` parameter.

# 1.0.0

- Initial release.
