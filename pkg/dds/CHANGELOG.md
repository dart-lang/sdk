# 1.3.5

- Fixed issue where clients subscribing to the `Service` stream were not being
  sent `ServiceRegistered` events on connection.

# 1.3.4

- Fixed issue where `isolateId`s were expected to take the form `isolates/123`
  although this is not required by the VM service specification.

# 1.3.3

- Fixed issue where `DartDevelopmentService.sseUri` did not return a URI with a
  `sse` scheme.

# 1.3.2

- Add IPv6 hosting support.
- Fix handling of requests that are outstanding when a client channel is closed.

# 1.3.1

- Fixed issue where an exception could be thrown during startup if the target
  process had an isolate without an associated pause event.

# 1.3.0

- Added support for SSE connections from web-based clients.

# 1.2.4

- Fixed another issue where a `StateError` could be raised within `DartDevelopmentService`
  when a client has disconnected after the target VM service has shutdown.

# 1.2.3

- Fixed issue where DDS was expecting a client provided implementation of
`compileExpression` to return a response with two layers of `response` objects.

# 1.2.2

- Fixed issue where a `StateError` could be raised within `DartDevelopmentService`
  when a client has disconnected after the target VM service has shutdown.

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
