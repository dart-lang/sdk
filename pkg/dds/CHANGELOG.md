# 2.7.6
- [DAP] `scopesRequest` now returns a `Globals` scope containing global variables for the current frame.
- [DAP] Responses to `breakpointRequest` will now have `verified: false` and will send `breakpoint` events to update `verified` and/or `line`/`column` as the VM resolves them.

# 2.7.5
- Updated `vm_service` version to >=9.0.0 <12.0.0.

# 2.7.4
- [DAP] Added support for `,d` (decimal), `,h` (hex) and `,nq` (no quotes) format specifiers to be used as suffixes to evaluation requests.
- [DAP] Added support for `format.hex` in `variablesRequest` and `evaluateRequest`.

# 2.7.3
- [DAP] Added support for displaying records in responses to `variablesRequest`.
- A new exception `ExistingDartDevelopmentServiceException` (extending `DartDevelopmentServiceException`) is thrown when trying to connect DDS to a VM Service that already has a DDS instance. This new exception contains a `ddsUri` field that is populated with the URI of the existing DDS instance if provided by the target VM Service.

# 2.7.2
- Update DDS protocol version to 1.4.
- [DAP] Forward any events from the VM Service's `ToolEvent` stream as `dart.toolEvent` DAP events.

# 2.7.1
- Updated `vm_service` version to >=9.0.0 <11.0.0.
- Simplified the DevTools URI composed by DDS.
- Fix issue where DDS was invoking an unimplemented RPC against a non-VM target.

# 2.7.0
- Added `DartDevelopmentService.setExternalDevToolsUri(Uri uri)`, adding support for registering an external DevTools server with DDS.

# 2.6.1
- [DAP] Fix a crash handling errors when fetching full strings in evaluation and logging events.

# 2.6.0
- Add support for registering and subscribing to custom service streams.
- [DAP] Supplying incorrect types of arguments in `launch`/`attach` requests will now result in a clear error message in an error response instead of terminating the adapter.

# 2.5.0
- [DAP] `variables` requests now treat lists from `dart:typed_data` (such as `Uint8List`) like standard `List` instances and return their elements instead of class fields.
- [DAP] `variables` requests now return information about the number of items in lists to allow the client to page through them.
- [DAP] `terminated` events are now always sent when detaching whether or not the debuggee terminates after unpause.
- [DAP] Debug adapters can now add/overwrite `orgDartlangSdkMappings` to control mappings of `org-dartlang-sdk:///` paths.

# 2.4.0
- [DAP] Added support for sending progress notifications via `DartDebugAdapter.startProgressNotification`.
  Standard progress events are sent when a clients sets `supportsProgressReporting: true` in its capabilities,
  unless `sendCustomProgressEvents: true` is included in launch configuration, in which case prefixed (`dart.`) custom notifications will be sent instead.

# 2.3.1
- Fixed issue where DDS wasn't correctly handling `Sentinel` responses in `IsolateManager.initialize()`.

# 2.3.0
- [DAP] Removed an unused parameter `resumeIfStarting` from `DartDebugAdapter.connectDebugger`.
- [DAP] Fixed some issues where removing breakpoints could fail if an isolate exited during an update or multiple client breakpoints mapped to the same VM breakpoint.
- [DAP] Paths provided to DAP now always have Windows drive letters normalized to uppercase to avoid some issues where paths may be treated case sensitively.
- Fixed issue where DDS wasn't correctly handling `Sentinel` responses in `IsolateManager.initialize()`.

# 2.2.6
- Fixed an issue where debug adapters would not automatically close after terminating/disconnecting from the debugee.

# 2.2.5
- Updated `devtools_shared` version to 2.14.1.

# 2.2.4
- Fix an issue where DAP adapters could try to remove the same breakpoint multiple times.

# 2.2.3
- Internal DAP changes.

# 2.2.2
- Updated `vm_service` version to 9.0.0.

# 2.2.1
- Reduce latency of `streamListen` calls through improved locking behavior.

# 2.2.0
- Add support for serving DevTools via `package:dds/devtools_server.dart`.

# 2.1.7
- Re-release 2.1.6+1.

# 2.1.6+3
- Roll back to 2.1.4.

# 2.1.6+2
- Roll back to 2.1.5.

# 2.1.6+1
- Fix dependencies.

# 2.1.6
- Improve performance of CPU sample caching.

# 2.1.5
- Update to new CpuSamplesEvent format for CPU sample caching for improved
  performance.
- Add additional context in the case of failure to ascii decode headers caused
  by utf8 content on the stream.

# 2.1.4
- A new library `package:dds/dap.dart` exposes classes required to build a custom DAP
  debug-adapter on top of the base Dart DAP functionality in DDS.
  For more details on DAP support in Dart see
  [this README](https://github.com/dart-lang/sdk/blob/main/pkg/dds/tool/dap/README.md).

# 2.1.3
- Ensure cancelling multiple historical streams with the same name doesn't cause an
  asynchronous `StateError` to be thrown.

# 2.1.2
- Silently handle exceptions that occur within RPC request handlers.

# 2.1.1
- Fix another possibility of `LateInitializationError` being thrown when trying to
  cleanup after an error during initialization.

# 2.1.0
- Added getAvailableCachedCpuSamples and getCachedCpuSamples.

# 2.0.2
- Fix possibility of `LateInitializationError` being thrown when trying to
  cleanup after an error during initialization.

# 2.0.1
- Update `package:vm_service` to ^7.0.0.

# 2.0.0
- **Breaking change:** add null safety support.
- **Breaking change:** minimum Dart SDK revision bumped to 2.12.0.

# 1.8.0
- Add support for launching DevTools from DDS.
- Fixed issue where two clients subscribing to the same stream in close succession
  could result in DDS sending multiple `streamListen` requests to the VM service.

# 1.7.6
- Update dependencies.

# 1.7.5
- Add 30 second keep alive period for SSE connections.

# 1.7.4
- Update `package:vm_service` to 6.0.1-nullsafety.0.

# 1.7.3
- Return an RpcException error with code `kServiceDisappeared` if the VM
  service connection disappears with an outstanding forwarded request.

# 1.7.2
- Fixed issue where a null JSON RPC result could be sent if the VM service
  disconnected with a request in flight (see https://github.com/flutter/flutter/issues/74051).

# 1.7.1
- Fixed issue where DartDevelopmentServiceException could have a null message.

# 1.7.0
- Added `package:dds/vm_service_extensions.dart`, which adds DDS functionality to
  `package:vm_service` when imported.
  - Added `onEventWithHistory` method and `onLoggingEventWithHistory`, 
    `onStdoutEventWithHistory`, `onStderrEventWithHistory`, and 
    `onExtensionEventWithHistory` getters.
- Added `getStreamHistory` RPC.

# 1.6.1
- Fixed unhandled `StateError` that could be thrown if the VM service disconnected
  while a request was outstanding.

# 1.6.0
- Added `errorCode` to `DartDevelopmentServiceException` to communicate the
  underlying reason of the failure.

# 1.5.1
- Improve internal error handling for situations with less than graceful
  shutdowns.

# 1.5.0
- Added event caching for `Stdout`, `Stderr`, and `Extension` streams. When a
client subscribes to one of these streams, they will be sent up to 10,000
historical events from the stream.

# 1.4.1
- Fixed issue where `evaluate` and `evaluateInFrame` requests were not being
  forwarded to the VM service properly when no external compilation service
  was registered.

# 1.4.0
- Added `done` property to `DartDevelopmentService`.
- Throw `DartDeveloperServiceException` when shutdown occurs during startup.
- Fixed issue where `StateError` was thrown when DDS was shutdown with pending
  requests.

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
