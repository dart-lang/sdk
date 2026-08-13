## 4.0.0
- **Breaking Change**: rename `EventParameters` constants to `DtdParameters`.
- **Breaking Change**: delete the `kFileSystemServiceName` constant in favor of
`FileSystemServiceConstants.serviceName`.
- **Breaking Change**: delete the `kUnifiedAnalyticsServiceName` constant in
favor of `UnifiedAnalyticsServiceConstants.serviceName`.
- Added `CoreDtdServiceConstants` and `FileSystemServiceConstants` for shared
use among DTD clients.

## 3.0.0

- Added `ConnectedAppService` to store the connections to Dart and Flutter
applications that DTD is aware of.
- Log exceptions from invalid `streamNotify` events.
- Added `getRegisteredServices` API.
- Added new response types `RegisteredServicesResponse` and
`VmServicesResponse`.
- **Breaking Change**: Changed the `serviceName` parameter for the
`DartToolingDaemon.call` method to have type `String?` instead of `String.`
- **Breaking Change**: When the `params` parameter for the
`DartToolingDaemon.call` method is null, pass the null value along to the client
peer request instead of sending an empty Map value.

## 2.5.1

- Widen the dependency on `unified_analytics` to include 8.0.0.

## 2.5.0

- Update SDK constraints to `^3.5.0`.
- Add `isClosed` getter to `DartToolingDaemon`.

## 2.4.0

- Bump `unified_analytics` dependency to ^7.0.0.

## 2.3.0

- Indicate compatibility with `package:web_socket_channel` 2.x and 3.x.
- Bump minimum version for `package:unified_analytics` to 6.1.0.
- `DartToolingDaemon.connect` will now wait for the web socket to be connected.
- The `DartToolingDaemon` constructor is now public and can be directly called
  with a `StreamChannel<String>`.
- The `params` parameter in `DartToolingDaemon.call()` has been changed from
  `Map<String, Object>?` to `Map<String, Object?>?`.
- `registerService` now allows passing a `Map<String, Object?>? capabilities`
  that can be supplied to clients via new `ServiceRegistered` and
  `ServiceUregistered` events on the `Service` stream (when connected to a
  version of DTD that supports these streams).
- Calling `DartToolingDaemon.onEvent()` now returns a broadcast stream. This
  means multiple listeners can be added, but also means you must add a listener
  prior to calling `streamListen` to avoid the possibility of missing events.

## 2.2.0

- Added new response types `Success`, `StringResponse`, `BoolResponse`, and `StringListResponse`.
- Added contributing guide (`CONTRIBUTING.md`).

## 2.1.0

- Added `getProjectRoots` API.
- Expose constant values from `dtd.dart`.

## 2.0.0

- Documentation improvements.
- Deprecate use of `DTDConnection` in favor of `DartToolingDaemon`.

## 1.0.0

- Solidified interface with dart tooling daemon.
- Added FileSystem service interface.

## 0.0.3

- Added types to service and extension exports.

## 0.0.2

- Added service and extension for accessing the file system through DTD.

## 0.0.1

- Initial version.
