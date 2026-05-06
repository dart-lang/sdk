## 27.1.1-wip

- Replace raw map for client ping checks with a proper `PingRequest` class and update client deserialization handling.

## 27.1.0

- Add `appName` to `DartDevelopmentServiceConfiguration`.

## 27.0.3

- Fix `dartExecutable` not being correctly passed to the DebugService.

## 27.0.2

- Add `dartExecutable` to `DartDevelopmentServiceConfiguration`.

## 27.0.1

- Replace `package:uuid` dependency with internal `Uuid` class for generating version 4 UUIDs.
- Add DDC Library Bundle tests in `dwds/test/integration/instances`.
- Fix WebSocket reconnection hang by ensuring Dart isolate recreation when a new browser client reuses an `AppDebugServices`.
- Don't inject script loads from within DWDS when executing with build_runner + DDC Module Bundles.
- Handle out of order disconnects and reconnects.
  - Update dwds to support ignoring disconnects for the SseHandler. This is
    useful to prevent incorrect behavior when a disconnect event arrives after
    a new connection request.
- Add sourcemap logic fixes to DDC Library Bundle + build_runner execution scheme.
- Update pathing logic for Windows and the DDC Library Bundle module system.
- Fix serialization of `HotRestartRequest` in `AppConnection`.
- Split integration tests across DDC module systems.
- Split additional tests across DDC module systems.
- Fix issue where `DebugConnection` did not complete `onDone` if `WebkitDebugger` fails to reconnect to the debugger after the connection closes.
- Fix `FormatException` in `ExtensionDebugger` by making `ExtensionEvent.fromJson` robust to missing headers and Map-typed params.
- Fix `StateError` in `DwdsInjector` during AOT execution by bundling `client.js` as a statically compiled asset.
- Report errors when an empty reloaded_sources.json is seen in the DDC Library Bundle module system.

## 27.0.0

- Remove `package:built_value`, `package:built_value_generator`, and `package:built_collection` dependencies.
- Remove `serializers.dart` and `data_serializers.dart`.
- Remove `package:built_value` dependency from `ConnectFailure`, `DebugStateChange`, `DevToolsOpener`, `DevToolsUrl`, `IsolateStart`, `IsolateExit`, `DevToolsRequest`, `DevToolsResponse`, `ExtensionRequest`, `ExtensionResponse`, `ExtensionEvent`, and `BatchedEvents`; switch to standard Dart JSON serialization.
- Update `ConnectFailure`, `DebugStateChange`, `DevToolsOpener`, `DevToolsUrl`, `DevToolsRequest`, `DevToolsResponse`, `ExtensionRequest`, `ExtensionResponse`, `ExtensionEvent`, `BatchedEvents` and `DebugInfo` serialization to mimic `built_value`'s list-based format to resolve compatibility issues with the debug extension.
- Remove `build`, `build_daemon`, `build_runner`, `build_version`, `build_web_compilers`, and `pubspec_parse` dependencies, along with `build.yaml` which originally generated `client.js` using `build_runner`. `client.js` is now compiled via `dart compile js` in a new `tool/build.dart` script.
- Throw `RPCError` when providing invalid `pause_isolates_on_start` values to the Chrome Proxy Service.
- Fix deserialization of `HotRestartRequest`, `HotReloadResponse`, `HotRestartResponse`, and `ServiceExtensionResponse` in the `DevHandler`.
- Add and export `BuildRunnerDdcLibraryBundleStrategyProvider`.
- Add support for Build Runner + DDC Module Bundle in test fixtures.
- Unify `assetHandler` and `assetReader` in `BuildRunnerStrategyProviderMixin`.
- Resolve test suite flakiness for port discovery.
- Bump `build_web_compilers` to ^4.4.12.

## 26.2.5

- Remove `package:built_value` dependency from `ErrorResponse` and `RegisterEvent`; switch to standard Dart JSON serialization.
- Adding retries to Chrome Proxy Service connections.

## 26.2.4

- Remove `package:built_value` dependency from `DebugEvent`, `BatchedDebugEvents`, `ConnectRequest`, `RunRequest`, `DebugInfo`, `HotReloadRequest`, `HotReloadResponse`, `HotRestartRequest`, `HotRestartResponse`, `ServiceExtensionRequest`, `ServiceExtensionResponse` and `BuildResult`; switch to standard Dart JSON serialization.
- Adding guards for dwds-injected library loading for Flutter Web.

## 26.2.3

- Bump `build_web_compilers` to ^4.4.1.
- Remove unused `clientFuture` arg from `DwdsVmClient` methods.
- Fix pausing starting of `main` after the hot restart.
- Updating bootstrapper for DDC library bundler module format + Frontend Server.
- Fix setting up breakpoints when handling in-app restarts with attached debugger.
- Fix issue where the web socket connections with the target application and Chrome debugger close when the computer sleeps.
- Fix setting up breakpoints when handling full reloads from attached
  debugger / page refreshes.

## 26.2.2

- Fix issue where isolate pause events were not reported correctly when using the web socket proxy service.

## 26.2.1

- Add support for DDS APIs and serving Dart DevTools when no Chrome Debugger is available.

## 26.2.0

- Add support for more service APIs over websocket connections when no Chrome Debugger is available.

## 26.1.0

- `reloadSources` and `hotRestart` now throw an RPC error with `kServerError` code when `NoClientsAvailableException` is caught (no browser clients are connected), allowing tooling to detect and handle this scenario.
- `pause` now does not send a `PauseInterrupted` event in
  `WebSocketProxyService` as we didn't actually pause.

## 26.0.0

- Bump SDK constraint to ^3.10.0
- Added 'scriptUri' parameter to compileExpressionToJs
- Fix an issue in `reloadSources` where a `PauseInterrupted` event was sent. - [#61560](https://github.com/dart-lang/sdk/issues/61560)
- Expose `dtdUri` via `DebugConnection`.

## 25.1.0

- Added `DartDevelopmentServiceConfiguration` to allow for configuring DDS behavior.
- Added support for serving DevTools via DDS. This will become the sole method of serving
  DevTools from DWDS in a future major release.
- Deprecated `spawnDds`, `ddsPort`, and `devToolsLauncher` properties in `DebugSettings`.
- Added `ddsConfiguration` to `DebugSettings`.

## 25.0.4

### Bug Fixes:

- Fix issue where `DebugService: Error serving requestsError: Unsupported operation: Cannot send Null`
  would be spammed on the console.

## 25.0.3

### Bug Fixes:

- Fix issue in hot restart with the web socket where we didn't pass the reloaded
  sources path, resulting in a null assertion.

## 25.0.2

### Bug Fixes:

- Fix issue where DDS would fail to initialize if DWDS already had existing
  clients.

## 25.0.1

### Bug Fixes:

- Fix issue in hot restart where a hot restart with no changes followed by one
  with changes, a `Future` was completed again, resulting in a crash.

## 25.0.0

- Implemented hot restart over websockets with multi window support.
- Fix refresh race condition bug by adding an isolate destruction grace period.
- Update a call to the `package:shelf_web_socket` `webSocketHandler()` function.

**Breaking changes**

- Remove deprecated parameter `injectDebuggingSupportCode` from `Dwds.start()`.
- Remove all deprecated fields, getters, and parameters
  related to the null safety compilation mode. Dart 3 only
  supports [sound null safety](https://dart.dev/null-safety).
- Rename `FrontendServerDdcLibraryBundleStrategy.hotReloadSourcesUri` to
  `reloadedSourcesUri`. The file that the `Uri` points to should now be updated
  for both a hot restart and a hot reload.

## 24.4.1

- Implemented a WebSocket-based communication protocol that provides essential developer tooling (hot reload, service extensions) when Chrome debugger access is unavailable. - [#2605](https://github.com/dart-lang/webdev/issues/2605)
- Added WebSocket-based hot reload and service extension support via new `WebSocketProxyService` class that implements VM service protocol over WebSockets.
- Enhanced `DevHandler` with `useWebSocketConnection` flag to toggle between Chrome-based and WebSocket-based communication protocols.
- Fixed an issue where we didn't wait until all scripts were parsed before
  recomputing metadata on a hot reload.

## 24.4.0

- Added support for breakpoint registering on a hot reload with the DDC library bundle format using PausePostRequests.
- `FrontendServerDdcLibraryBundleStrategy.hotReloadSourceUri` is now expected to also provide the reloaded modules.

## 24.3.11

- Changed DWDS to always inject the client and added `useDwdsWebSocketConnection` flag to control communication protocol: when true uses socket-based implementation, when false uses Chrome-based communication protocol.
- Added WebSocket-based hot reload support: `reloadSources` in `ChromeProxyService` and `DevHandler` now handle hot reload requests and responses over WebSockets.
- Refactored the injected client to use a reusable function for handling hot reload requests and responses over WebSockets.
- Added support for breakpoint registering on a hot restart with the DDC library bundle format using PausePostRequests.

## 24.3.10

- Disabled breakpoints on changed files in a hot reload. They currently do not
  map to the correct locations or are broken, so disable them for now. - [#60186](https://github.com/dart-lang/sdk/issues/60186)

## 24.3.9

- Renamed DWDS Injector parameter `enableDebuggingSupport` to `injectDebuggingSupportCode` for clearer intent.

## 24.3.8

- Updated DWDS to include a boolean flag that enables debugging support only when set to true. [#60289](https://github.com/dart-lang/sdk/issues/60289)

## 24.3.7

- The registered extension `reassemble` is now no longer called when calling
  `reloadSources`. Users should call `reassemble` using `callServiceExtension`.

- `callServiceExtension` now checks the runtime for the list of registered
  service extensions. It also now throws a `RPCError` with
  `RPCErrorKind.kMethodNotFound` when a service extension is not found instead
  of throwing a JS evaluation error.

## 24.3.6

- Bump minimum sdk version to 3.7.0
- use 'compile js-dev' instead of directly invoking the ddc snapshot.
- `FrontendServerDdcLibraryBundleStrategy` now takes a `hotReloadSourcesUri`
  parameter in order to fetch the file that contains the changed sources and
  libraries instead of assuming it exists in the global `window`.

## 24.3.5

- Allow clients to specify the `packageConfigPath` in `LoadStrategy` class and associated providers.

## 24.3.4

- Added support for some debugging APIs with the DDC library bundle format. - [#2566](https://github.com/dart-lang/webdev/issues/2566), [#2573](https://github.com/dart-lang/webdev/issues/2573)
- Added support for hot reload using the DDC library bundle format.

## 24.3.3

- Added support for some debugging APIs with the DDC library bundle format. - [#2563](https://github.com/dart-lang/webdev/issues/2563)
- Update `DCM` version to `1.26.0-1`
- Add support for hot restart using the DDC library bundle format.

## 24.3.2

- Bump `package:dds` to `>=4.2.5 <6.0.0`.

## 24.3.1

- Add support for binding DDS to a custom port.

## 24.3.0

- Update to be forward compatible with changes to `package:shelf_web_socket`.
- Added support for some debugging APIs with the DDC library bundle format. - [#2537](https://github.com/dart-lang/webdev/issues/2537),[#2544](https://github.com/dart-lang/webdev/issues/2544),[#2548](https://github.com/dart-lang/webdev/issues/2548)
- Fix issue where batched expression evals were failing if any subexpression failed. - [#2551](https://github.com/dart-lang/webdev/issues/2551)
- Expose a partial implementation of
  `FrontendServerDdcLibraryBundleStrategyProvider`.
- Update `package:vm_service_interface` to '^2.0.1'.

## 24.2.0

- Consolidate `FrontendServerDdcStrategyProvider` and `FrontendServerRequireStrategyProvider` under a shared parent class. - [#2517](https://github.com/dart-lang/webdev/issues/2517)
- Remove `build_daemon_ddc_and_canary_evaluate_test`. - [2512](https://github.com/dart-lang/webdev/issues/2512)
- Replace deprecated JS code `this.__proto__` with `Object.getPrototypeOf(this)`. - [#2500](https://github.com/dart-lang/webdev/pull/2500)
- Migrate injected client code to `package:web`. - [#2491](https://github.com/dart-lang/webdev/pull/2491)
- Deprecated MetadataProvider's, CompilerOptions', SdkConfiguration's & SdkLayout's soundNullSafety. - [#2427](https://github.com/dart-lang/webdev/issues/2427)
- Add load strategy and an unimplemented hot restart strategy for DDC library
  bundle format.
- Added `useModuleName` option to `MetadataProvider` to determine whether or not
  to use the provided `name` in a `ModuleMetadata`. Metadata provided by DDC
  when using the library bundle format does not provide a useful bundle name.
- Migrate to `package:web` v1.1.0.
- Added support for some debugging APIs with the DDC library bundle format. - [#2488](https://github.com/dart-lang/webdev/issues/2488), [#2534](https://github.com/dart-lang/webdev/issues/2534)
- Update `package:vm_service` to '>=14.2.4 <16.0.0'.
- Update `package:vm_service_interface` to '2.0.1'.

## 24.1.0

- Fix bug where debugging clients are not aware of service extensions when connecting to a new web app. - [#2388](https://github.com/dart-lang/webdev/pull/2388)
- Respect the value of `pause_isolates_on_start` during page-refreshes. - [#2431](https://github.com/dart-lang/webdev/pull/2431)
- Fix issue where DAP clients wouldn't resume after a restart. - [#2441](https://github.com/dart-lang/webdev/pull/2441)
- Add implementation for the VM Service's `getFlagList` API. - [#2438](https://github.com/dart-lang/webdev/pull/2438)
- Hide more variables from the local scope when debugging. These variables were synthetically added by the compiler to
  support late local variables and don't appear in the original source code. - [#2445](https://github.com/dart-lang/webdev/pull/2445)
- Spawn DDS in a separate process using `dart development-service` instead of launching from `package:dds`. - [#2466](https://github.com/dart-lang/webdev/pull/2466)
- Update package `web_socket_channel: '>=2.2.0 <4.0.0'`.
- Require Dart `^3.4`
- Prepare to update `package:vm_service_interface` constraint to `2.0.0`.

## 24.0.0

- Implement `setFlag` when it is called with `pause_isolates_on_start`. - [#2373](https://github.com/dart-lang/webdev/pull/2373)
- Do not persist breakpoints across hot restarts or page reloads. - [#2371](https://github.com/dart-lang/webdev/pull/2371)
- If `pause_isolates_on_start` is `true`, wait for `resume` to run the app's `main` method. - [#2378](https://github.com/dart-lang/webdev/pull/2378)
- Fix bug where setting breakpoints in a project using macros would fail. - [#2403](https://github.com/dart-lang/webdev/pull/2403)
- Make stack trace calculation resilient against one frame throwing an error. - [#2408](https://github.com/dart-lang/webdev/pull/2408)

**Breaking changes**

- Rename `dart_library.js` to `ddc_module_loader.js` to match SDK naming changes. - [#2360](https://github.com/dart-lang/webdev/pull/2360)

## 23.3.0

- Filter out internal type properties from the new DDC type system. - [#2348](https://github.com/dart-lang/webdev/pull/2348)
- Fix errors on displaying getters when debugging in VS Code. - [#2343](https://github.com/dart-lang/webdev/pull/2343)

## 23.2.0

- Send untruncated `dart:developer` logs to debugging clients. - [#2333](https://github.com/dart-lang/webdev/pull/2333)
- Enabling tests that run with the DDC module system and exposing `utilities/ddc_names.dart` - [#2295](https://github.com/dart-lang/webdev/pull/2295)

## 23.1.1

- Loosen `package:vm_service` constraints to allow `>=13.0.0 <15.0.0`. - [#2329](https://github.com/dart-lang/webdev/pull/2329)

## 23.1.0

- Update `package:vm_service` constraints to allow version `14.x.x`. - [#2307](https://github.com/dart-lang/webdev/pull/2307)

## 23.0.0

- Restructure `LoadStrategy` to provide build settings. - [#2270](https://github.com/dart-lang/webdev/pull/2270)
- Add `FrontendServerLegacyStrategyProvider` and update bootstrap generation logic for `LegacyStrategy` - [#2285](https://github.com/dart-lang/webdev/pull/2285)
- Tolerate failures to detect a Dart execution context. - [#2286](https://github.com/dart-lang/webdev/pull/2286)
- Fix a null cast error when debugging a `Class` from VS Code. - [#2303](https://github.com/dart-lang/webdev/pull/2303)
- Update `package:vm_service` constraint to `^14.0.0`. - [#2307](https://github.com/dart-lang/webdev/pull/2307)
- Update `package:vm_service_interface` constraint to `1.0.1`. - [#2307](https://github.com/dart-lang/webdev/pull/2307)

## 22.1.0

- Update `package:vm_service` constraint to `^13.0.0`. - [#2265](https://github.com/dart-lang/webdev/pull/2265)

## 22.0.0

- Update the interface for ChromeProxyService.getSourceReport to match the VM service. - [#2235](https://github.com/dart-lang/webdev/pull/2235)
- Update `package:vm_service` constraint to `^12.0.0`. - [#2248](https://github.com/dart-lang/webdev/pull/2248)

**Breaking changes**

- Refactor the parameters to `Dwds.start`. - [#2231](https://github.com/dart-lang/webdev/pull/2231).
- Add a new parameter `workspaceName` to the `ToolConfiguration` passed to `Dwds.start`. - [#2237](https://github.com/dart-lang/webdev/pull/2237)

## 21.0.0

- Update Dart SDK constraint to `>=3.2.0-36.0.dev <4.0.0`. - [#2207](https://github.com/dart-lang/webdev/pull/2207)

**Breaking changes**

- Allow clients to specify where to find the package config. - [#2203](https://github.com/dart-lang/webdev/pull/2203).
- Allow clients to specify a way to convert absolute paths to g3-relative paths. - [#2200](https://github.com/dart-lang/webdev/pull/2200)

## 20.0.1

- Update file dependency to `>=6.0.0 < 8.0.0` - [#123260](https://github.com/flutter/flutter/pull/123260#issuecomment-1674001623).

## 20.0.0

- Require clients to specify the `basePath` on `AssetReader`. - [#2160](https://github.com/dart-lang/webdev/pull/2160)
- Update SDK constraint to `>=3.1.0-254.0.dev <4.0.0`. - [#2169](https://github.com/dart-lang/webdev/pull/2169)
- Require min `build_web_compilers` version `4.0.4` - [#2171](https://github.com/dart-lang/webdev/pull/2171)
- Switch to using new debugging API from DDC to support new type system. - [#2159](https://github.com/dart-lang/webdev/pull/2159)
- Fix Flutter crash when calling `resume` when app is not paused. - [#2188](https://github.com/dart-lang/webdev/pull/2188)
- Update file dependency to `7.0.0`.

## 19.0.2

- Fix Flutter crash due to potential null value in `setUpChromeConsoleListener`. - [#2162](https://github.com/dart-lang/webdev/pull/2162)

## 19.0.1

- Do not show async frame errors on evaluation. - [#2073](https://github.com/dart-lang/webdev/pull/2073)
- Refactor code for presenting record instances. - [#2074](https://github.com/dart-lang/webdev/pull/2074)
- Display record types concisely. - [#2070](https://github.com/dart-lang/webdev/pull/2070)
- Display type objects concisely. - [#2103](https://github.com/dart-lang/webdev/pull/2103)
- Support using scope in `ChromeProxyService.evaluateInFrame`. - [#2122](https://github.com/dart-lang/webdev/pull/2122)
- Check for new events more often in batched stream. - [#2123](https://github.com/dart-lang/webdev/pull/2123)
- Map Chrome error on `resume` to the same error returned by the Dart VM. - [#2133](https://github.com/dart-lang/webdev/issues/2133)
- VM service API methods throw type `RPCError`, same as the Dart VM. - [#2144](https://github.com/dart-lang/webdev/pull/2144)

## 19.0.0

- Allow clients to specify the connected app's entrypoint file. - [#2047](https://github.com/dart-lang/webdev/pull/2047)
- Don't include non-instantiated variables in stack frame data. - [#2061](https://github.com/dart-lang/webdev/pull/2061)
- Fix `getObject` failure on record class - [2063](https://github.com/dart-lang/webdev/pull/2063)

## 18.0.2

- Support new DDC temp names for patterns. - [#2042](https://github.com/dart-lang/webdev/pull/2042)
- Make debugger find next dart location when stepping. -[#2043](https://github.com/dart-lang/webdev/pull/2043)

## 18.0.1

- Fix failure to map JS exceptions to dart. - [#2004](https://github.com/dart-lang/webdev/pull/2004)
- Fix for listening to custom streams. - [#2011](https://github.com/dart-lang/webdev/pull/2011)
- Handle unexpected extension debugger disconnect events without crashing the app - [#2021](https://github.com/dart-lang/webdev/pull/2021)
- Support `Set` inspection. - [#2024](https://github.com/dart-lang/webdev/pull/2024)

## 18.0.0

- Cleanup `getObject` code for lists and maps.
  - Now works with offset `0` and `null` count.
  - Fix failures on edge cases.
- Support records:
  - Update SDK constraint to `>=3.0.0-188.0.dev <4.0.0`.
  - Update `package:vm_service` constraint to `>=10.1.2 <12.0.0`.
  - Update `package:dds` constraint to `^2.7.1`.
  - Fill `BoundField.name` for records.
  - Display records as a container of fields.
- Remove test-only code from `sdk_configuration.dart`.
- Move shared test-only code to a new `test_common` package.
- Convert unnecessary async code to sync.
- Allow empty scopes in expression evaluation in a frame.

**Breaking changes**

- Require `sdkConfigurationProvider` in `ExpressionCompilerService`
  constructor.
- Change DWDS parameter `isFlutterApp` from type `bool?` to type
  `Future<bool> Function()?`.

## 17.0.0

- Include debug information in the event sent from the injected client to the
  Dart Debug Extension notifying that the Dart app is ready.
- Fix null cast error on expression evaluations after dwds fails to find class
  metadata.
- Include the entire exception description up to the stacktrace in
  `mapExceptionStackTrace`.
- Allow enabling experiments in the expression compiler service.
- Pre-warm expression compiler cache to speed up Flutter Inspector loading.
- Display full error on failure to start DDS.
- Fix crash on processing DevTools event when starting DevTools from DevTools
  uri.
- Prepare or Dart 3 alpha breaking changes:
  - Move weak null safety tests to special branch of `build_web_compilers`.
  - Do not pass `--(no)-sound-null-safety` flag to build daemon.
- Add back `ChromeProxyService.setExceptionPauseMode()` without override.
- Make hot restart atomic to prevent races on simultaneous execution.
- Return error on expression evaluation if expression evaluator stopped.
- Update SDK constraint to `>=3.0.0-134.0.dev <4.0.0`.
- Update `package:vm_service` constraint to `>=10.1.0 <12.0.0`.
- Fix expression compiler throwing when weak SDK summary is not found.

**Breaking changes**

- Include an optional param to `Dwds.start` to indicate whether it is running
  internally or externally.
- Include an optional param to `Dwds.start` to indicate whether it a Flutter
  app or not.
- Remove `sdkConfigurationProvider` parameter from `Dwds.start`.
- Remove deprecated `ChromeProxyService.setExceptionPauseMode()`.
- Support dart 3.0-alpha breaking changes:
  - Generate missing SDK assets for tests.
  - Enable frontend server null safe tests.
  - Update `build_web_compilers` constraint to `^4.0.0`.
  - Update `build_runner` constraint to `^2.4.0`.
  - Support changes in the SDK layout for dart 3.0.

## 16.0.1

- Allow the following API to return `null` and add error handling:
  - `LoadStrategy.serverPathForModule`
  - `LoadStrategy.sourceMapPathForModule`
- Expression evaluation performance improvement:
  - Batch `ChromeProxyService.evaluate()` requests that are close in time and
    are executed in the same library and scope.
- Update `package:file` version to `6.13` or greater to handle
  https://github.com/dart-lang/sdk/issues/49647.

## 16.0.0

- Fix a hang and report errors on hot reload exceptions from the injected
  client.
- Remove `AppInspector.evaluate` code that has been replaced by expression
  evaluation using a compiler in all scenarios.
- Fix a bug where evaluation would fail with more than one parameter in the
  scope.
- Remove showing un-captured values from the stack during evaluation.
- Refactor code to break most circular dependencies between files.
- Migrate `package:dwds` to null safety.
- Make `ChromeProxyService.getStack` wait for the debugger to perform initial
  resume operation. This avoids race conditions on isolate start.
- Make server paths match directory structure
  - Allows correct relative source map paths resolution.
  - Add `PackageUriMapper` class to allow mapping uris to server paths.
- Update the min SDK constraint to 2.18.0.
- Make DartUri work for `google3:` uris.

**Breaking changes**

- Remove no longer used `ExpressionCompilerService.handler`.
- Remove `assetHandler` parameter from `ExpressionCompilerService` constructor.
- Add `packageUriMapper` parameter to the constructor of
  `FrontendServerRequireStrategyProvider`.

## 15.0.0

- Port some `dwds` files to null safety.
- Fix failing `frontend_server_evaluate` tests.
- Prevent `flutter_tools` crash when the Dart execution context cannot be found.
- Update method signature of `lookupResolvedPackageUris`.

## 14.0.3

- Make data types null safe.
- Update `package:vm_service` to 8.3.0.
- Convert JavaScript stack traces in uncaught exceptions to Dart stack traces.
- Fix failure to set breakpoints on windows with a base change in index.html.
- Add the `setIsolatePauseMode` method to Chrome Proxy Service.
- Batch extension `Debugger.scriptParsed` events and send batches every 1000ms
  to the server.
- Move `batched_stream.dart` into shared utilities.
- Update the method signature for `lookupResolvedPackageUris`.

## 14.0.2

- Update the min SDK constraint to 2.17.0.

## 14.0.1

- Add `libraryFilters` optional parameter to the vm service implementation of
  `getSourceReport`.
- Update temp variable detection heuristics so internal JS type objects do not
  show in the debugger.

## 14.0.0

- Add column information to breakpoints to allow precise breakpoint placement.
- Split SDK validation methods to allow validation of separate components.
- Remove dependency on `package:_fe_analyzer_shared`. Note: this removes current
  incomplete support for resolving `dart:` uris.
- Fix issues discovered when using flutter tools with web server device:
  - Remove `dart:web_sql` from the list of SDK libraries as it is no longer
    used.
  - Fix crash when using flutter tools with web server device.
  - Remove clearing all scripts on page load for extension debugger.
- Fix breakpoints not hitting after changing a base in index.html.
- Find best locations for call frames, breakpoints, or expression evaluation.
- Close the SSE connection when a DebugExtension.detached event is received.
- Fix issues discovered when using legacy module system, debug extension, and
  JIT modules:
  - Improve step-into times by not stepping into library loading code.
  - Fix incorrect skip lists due to unsorted locations.
  - Fix memory leak in extension debugger by removing stale script IDs.
  - Allow mapping JS locations to Dart locations matching other JS lines, to
    match the behavior of Chrome DevTools.
  - Fix expression evaluation failure if debugger is stopped in the middle of a
    variable definition.

**Breaking changes:**

- Add `basePath` parameter to `FrontendServerRequireStrategy`.
- Add `loadLibrariesModule` getter to `LoadStrategy` interface.

## 13.1.0

- Update \_fe_analyzer_shared to version ^38.0.0.

## 13.0.0

- Change wording of paused overlay from "Paused in Dart DevTools" to "Paused"
- Allow sending back the Dart DevTools URL from DWDS instead of launching Dart
  DevTools, to support embedding Dart DevTools in Chrome DevTools.
- Temporarily disable the paused in debugger overlay.
- Add `SdkConfiguration` and `SdkConfigurationProvider` classes to allow for
  lazily created SDK configurations.
- Fix an issue in reporting DevTools stats where the DevTools load time was not
  always recorded.
- Add an `ide` query parameter to the Dart DevTools URL for analytics.
- Fix a race where injected client crashed on events send just before hot
  restart.
- Remove verbose printing on receiving DevTools events.
- Update `vm_service` version to `^8.2.0`.
- Migrate .packages to package_config.json.
- Update error message on expression evaluation using unloaded libraries.
- Add `screen` field to the `DebuggerReady` event.
- Report `DebuggerReady` events for DevTools embedded into Chrome Devtools.
- Fix missing `CallFrame.url` after update to Chrome 100.

**Breaking changes:**

- `Dwds.start` and `ExpressionCompilerService` now take
  `sdkConfigurationProvider` argument instead of separate SDK-related file
  paths.

## 12.1.0

- Update \_fe_analyzer_shared to version ^34.0.0.

## 12.0.0

- Implement `lookupResolvedPackageUris` and `lookupPackageUris` vm service API.
- Update `vm_service` version to `^8.1.0`.
- Make `ExpressionCompilerService` infer location of `libraries.json` from
  `sdkDir` parameter.
- Show an alert in the Dart Debug Extension for a multi-app scenario.
- Fix a bug where `dartEmitDebugEvents` was set as a `String` instead of `bool`
  in the injected client.
- Emit a warning instead of crashing on missing `libraries.json`.
- Remove dead code for reading `'dart.developer.registerExtension'` and
  `'dart.developer.postEvent'` events from the chrome console. These messages
  haven't been written to the console since dwds v11.1.0 and Dart SDK v2.14.0.
- Batch debug events sent from injected client to dwds to relieve network load.
- Update `_fe_analyzer_shared` version to `33.0.0`
- Update the Dart minimum SDK to `>=2.16.0`.

**Breaking changes:**

- Add `sdkDir` and `librariesPath` arguments to `Dwds.start` to help file
  resolution for sdk uris.
- Add `emitDebugEvents` argument to `Dwds.start` to suppress emitting debug
  events from the injected client.
- Replace `sdkRoot` parameter by `sdkDir` in `ExpressionCompilerService`.
- Adds an additional parameter to launch Dart DevTools in the same window as the
  connected Dart app.

## 11.5.1

- Update SDK constraint to `>=2.15.0 <3.0.0`.

## 11.5.0

- Support hot restart in a multi-app scenario with legacy modules.
  - Rename `$dartHotRestart` in the injected client to `$dartHotRestartDwds`.
  - Make `$dartHotRestartDwds` take a `runId`.
  - No change in behavior for single applications.
  - For a multi-app scenario using legacy modules, this will make all sub-apps
    with the same `runId` restart at the same time once.

  Note that multi-app scenario is currently only supported for legacy modules,
  used by DDR, and is not yet supported for amd modules that are used by flutter
  tools and webdev.

- Fix chrome detection in iPhone emulation mode in chrome or edge browsers.

- Reliably find unused port for extension backend http service.

- Ignore offset / count parameters in getObject if the object has no length.

- Include static member information for classes.

## 11.4.0

- Fix duplicated scripts returned by `VmService.getScripts` API.
- Handle and log http request serving errors.
- Encode extension url asynchronously.
- Use default constant port for debug service.
  - If we fail binding to the port, fall back to previous strategy of finding
    unbound ports.
- Add metrics measuring
  - DevTools Initial Page Load time
  - Various VM API
  - Hot restart
  - Http request handling exceptions
- Only return scripts included in the library with Library object.
- Add `ext.dwds.sendEvent` service extension to dwds so other tools can send
  events to the debugger. Event format:
  ```
  {
    'type': '<event type>',
    'payload': {
      'screen: '<screen name>',
      'action: '<action name>'
    }
  }
  ```
  Currently supported event values:
  ```
  {
    'type: 'DevtoolsEvent',
    'payload': {
      'screen': 'debugger',
      'action': 'pageReady'
    }
  }
  ```

## 11.3.0

- Update SDK constraint to `>=2.14.0 <3.0.0`
- Depend on `vm_service` version `7.3.0`.

## 11.2.3

- Fix race causing intermittent `Aww, snap` errors on starting debugger with
  multiple breakpoints in source.
- Fix needing chrome to be focus in order to wait for the isolate to exit on hot
  restart.

## 11.2.2

- Depend on `dds` version `2.1.1`.
- Depend on `vm_service` version `7.2.0`.

## 11.2.1

- Recover from used port errors when starting debug service.
- Update min SDK constraint to `2.13.0`.

## 11.2.0

- Throw `SentinelException` instead of `RPCError` on vm service API on
  unrecognized isolate.
- Throw `RPCError` in `getStack` if the application is not paused.
- Recognize `dart:ui` library when debugging flutter apps.
- Fix hang on hot restart when the application has a breakpoint.
- Fix out of memory issue during sending debug event notifications.

## 11.1.2

- Return empty library from `ChromeProxyService.getObject` for libraries present
  in metadata but not loaded at runtime.
- Log failures to load kernel during expression evaluation.
- Show lowered final fields using their original dart names.
- Limit simultaneous connections to asset server to prevent broken sockets.
- Fix hangs in hot restart.
- Initial support for passing scope to `ChromeProxyService.evaluate`.
- Require `build_web_compilers` version `3.0.0` so current version of dwds could
  be used with SDK stable `2.13.x` versions.

## 11.1.1

- Update versions of `package:sse`, `package:vm_service`, `package:dds`.

## 11.1.0

- Add global functions to the injected client for `dart.developer.postEvent` and
  `dart.developer.registerExtension`.
- Register new service extension `ext.dwds.emitEvent` so clients can emit
  events. This is intended to be used for analytics.

## 11.0.2

- Implement `_flutter.listViews` extension method in dwds vm client.

## 11.0.1

- Make adding and removing breakpoints match VM behavior:
  - Allow adding existing breakpoints.
  - Throw `RPCError` when removing non-existent breakpoints.

## 11.0.0

- Do not send `kServiceExtensionAdded` events to subscribers on the terminating
  isolate during hot restart.
- Support `vm_service` version `6.2.0`.
- Fix missing sdk libraries in `getObject()` calls.
- Fix incorrect `rootLib` returned by `ChromeProxyService`.
- Fix not working breakpoints in library part files.
- Fix data race in calculating locations for a module.
- Fix uninitialized isolate after hot restart.
- Fix intermittent failure caused by evaluation not waiting for dependencies to
  be updated.
- The injected client now posts a top level event when the Dart application is
  loaded. This event is intended to be consumed by the Dart Debug Extension.

**Breaking changes:**

- `Dwds.start` no longer supports automatically injecting a devtools server. A
  `devtoolsLauncher` callback must be provided to support launching devtools.

## 10.0.1

- Support `webkit_inspection_protocol` version `^1.0.0`.

## 10.0.0

- Support `VMService.evaluate` using expression compiler.
- Update min sdk constraint to `>=2.13.0-144.0.dev`.
- Throw `RPCError` on evaluation if the program is not paused.
- Record `ErrorRef` returned by evaluation in analytics.

**Breaking changes:**

- Change `ExpressionCompiler.initialize` method to include module format.
- Add `LoadStrategy.moduleFormat` to be used for communicating current module
  format to the expression compiler.

## 9.1.0

- Support authentication endpoint for the Dart Debug Extension.
- Support using WebSockets for the injected client by passing
  `useSseForInjectedClient: false` to `Dwds.start()`. Unlike SSE, WebSockets do
  not currently support keepAlives here (beyond the standard WebSocket pings to
  keep the socket alive).

## 9.0.0

- Fix an issue where relative worker paths provided to the
  `ExpressionCompilerService` would cause a crash.
- Fix an issue where the injected client connection could be lost while the
  application is paused.
- Support keep-alive for debug service connections.
- Depend on the latest `package:sse`.
- Filter out DDC temporary variables from the variable inspection view.
- Add `DwdsEvent`s around stepping and evaluation.
- Send an event to the Dart Debug Extension that contains VM service protocol
  URI.
- Depend on `package:vm_service` version `6.1.0+1`.
- Update the `keepAlive` configs to prevent accidental reuse of a connection
  after stopping a debug session.
- Support disabling the launching of Dart DevTools through `Alt + d` with
  `enableDevtoolsLaunch`.
- Opt all dart files out of null safety for min SDK constraint update.

**Breaking changes:**

- `LoadStrategy`s now require a `moduleInfoForEntrypoint`.

## 8.0.3

- Fix an issue where failed hot restarts would hang indefinitely.

## 8.0.2

- Change `ExpressionCompiler` to accept `FutureOr<int>` port configuration.
- Depend on `package:vm_service` version `6.0.1-nullsafety.1`.

## 8.0.1

- Support null safe versions of `package:crypto`, `package:uuid` and
  `package:webdriver`.

## 8.0.0

- Improve logging around execution contexts.
- Remove the expression compilation dependency update from the create isolate
  critical path.
- Expose new event stream for future use with analytics.
- Update `ExpressionCompiler` to include new `initialize` method which has a
  parameter for the null safety mode.
- Update `ExpressionCompilerService` to change how it is instantiated and
  implement the new `initialize` method.
- Provide summary module paths to the expression compiler
- Depend on `package:vm_service` version `6.0.1-nullsafety.0`.

**Breaking changes:**

- Change `ExpressionCompiler.updateDependencies` method to include module
  summary paths

## 7.1.1

- Properly handle `requireJS` errors during hot restarts.
- Fix an issue where Dart frame computation could result in a stack overflow for
  highly nested calls.
- Fix an issue where calling add breakpoint in quick succession would corrupt
  the internal state.
- Fix expression evaluation failure inside blocks.
- Now log the encoded URI of the debug service to both the terminal and
  application console.
- No longer blacklist the Dart SDK as the `skipLists` support serves the same
  purpose.
- Fix an issue where running webdev with expression evaluation enabled would
  fail to find `libraries.json` file and emit severe error.

## 7.1.0

- Fix a potential null issue while resuming.
- Depend on the latest `package:vm_service`.
- Fix crash in expression evaluation on null isolate.
- Fix incorrect file name detection for full kernel files.
- Add `ExpressionCompilerService.startWithPlatform` API to enable running
  expression compiler worker from a given location.
- Support Chrome `skipLists` to improve stepping performance.
- Export `AbsoluteImportUriException`.
- Depend on the latest `package:vm_service` which supports a new `limit`
  parameter to `getStack`.

## 7.0.2

- Depend on the latest `package:sse`.
- Add more verbose logging around `hotRestart`, `fullReload` and entrypoint
  injection.

## 7.0.1

- Fix an issue where we attempted to find locations for the special
  `dart_library` module.

## 7.0.0

- Add support for the Dart Development Service (DDS). Introduces 'single client
  mode', which prevents additional direct connections to DWDS when DDS is
  connected.
- Update metadata reader version to `2.0.0`. Support reading metadata versions
  `2.0.0` and `1.0.0`.
- Support custom hosts and HTTPs traffic in a `ProxyServerAssetReader`.
- Remove heuristics from require strategies and use metadata to look up module
  paths.
  - Fix issue where upgrading `build_web_compilers` would cause missing module
    assets (JavaScript code and source maps).
- Fix issue where open http connections prevent the process for exiting.
- Add `ExpressionCompilationService` class that runs ddc in worker mode to
  support expression evaluation for clients that use build systems to build the
  code.
- Require at least `devtools` and `devtools_server` version `0.9.2`.
- Require at least `dds` version `1.4.1`.
- Require at least `build_web_compilers` version `2.12.0`.
- Update min sdk constraint to `>=2.10.0`.
- Update `MetadataProvider` to throw an `AbsoluteImportUriException` when
  absolute file paths are used in an import uri.

**Breaking changes:**

- Change `ExpressionCompiler` to require a new `updateDependencies` method.
- Update a number of `LoadStrategy` APIs to remove heuristics and rely on the
  `MetadataProvider`.
- No longer require a `LogWriter` and corresponding `verbose` argument but
  instead properly use `package:logger`.
- `FrontendServerRequireStrategyProvider` now requires a `digestProvider`.

## 6.0.0

- Depend on the latest `package:devtools` and `package:devtools_server`.
- Support using WebSockets for the debug backend by passing
  `useSseForDebugBackend: false` to `Dwds.start()`
- Ensure we run main on a hot restart request even if no modules were updated.
- Allow reading metadata generated by `dev_compiler` from file to supply module
  information to `Dwds`.
- Hide JavaScript type errors when hovering over text in the debugger.
- Fix an issue where reusing a connection could cause a null error.
- Improve the heuristic which filters JS scopes for debugging needs.

**Breaking Changes:**

- Require access to the `.ddc_merged_metadata` file.
- Remove deprecated parameter `restoreBreakpoints` as breakpoints are now set by
  regex URL and Chrome automatically reestablishes them.

## 5.0.0

- Have unimplemented VM service protocol methods return the RPC error
  'MethodNotFound' / `-32601`.
- Fix an issue where the application main function was called before a hot
  restart completed.
- Breaking change `AssetReader` now requires a `metadataContents`
  implementation.

## 4.0.1

- Fixed issue where `getSupportedProtocols` would return the wrong protocol.

## 4.0.0

- Pin the `package:vm_service` version to prevent unintended breaks.

## 3.1.3

- Fix an issue where the injected client served under `https` assumed the
  corresponding SSE handler was also under `https`.

## 3.1.2

- Gracefully handle multiple injected clients on a single page.
- Update to the latest `package:vm_service` and use more RPCError error codes on
  call failures.
- Update the `require_restarter` to rerun main after a hot restart to align with
  the legacy strategy. We therefore no longer send a `RunRequest` after a hot
  restart.
- Compute only the required top frame for a paused event.
- Change `streamListen` to return an `RPCError` / error code `-32601` for
  streams that are not handled.
- Populate information about async Dart frames.
- Populate the `exception` field in debugger pause event when we break as a
  result of an exception.
- Prompt users to install the Dart Debug Extension if local debugging does not
  work.
- Allow for the injected client to run with CSP enforced.
- Implement the `getMemoryUsage()` call.
- Fix an issue where the injected client could cause a mixed content error.

## 3.1.1

- Change the reported names for isolates to be more terse.
- Implemented the 'PossibleBreakpoints' report kind for `getSourceReport()`.
- Change the returned errors for the unimplemented `getClassList` and
  `reloadSources` methods to -32601 ('method does not exist / is not
  available').
- Do not include native JavaScript objects on stack returned from the debugger.

## 3.1.0

- Support Chromium based Edge.
- Depend on latest `package:sse` version `3.5.0`.
- Bypass connection keep-alives when shutting down to avoid delaying process
  shutdown.
- Fix an issue where the isolate would incorrectly be destroyed after connection
  reuse.

## 3.0.3

- Support the latest version of `package:shelf_packages_handler`.
- Throw a more useful error if during a hot restart there is no active isolate.
- Fix a race condition in which loading module metadata could cause a crash.
- Correct scope detection for expression evaluation
- Silence verbose and recoverable exceptions during expression evaluation
- Return errors from ChromeProxyService.evaluateInFrame as ErrorRef so they are
  not shown when hovering over source in the IDE

## 3.0.2

- Fix an issue in JS to Dart location translation in `ExpressionEvaluator`. JS
  location returned from Chrome is 0-based, adjusted to 1-based.

## 3.0.1

- Drop dependency on `package_resolver` and use `package_config` instead.
- Bump min sdk constraint to `>=2.7.0`.

## 3.0.0

- Depend on the latest `package:vm_service` version `4.0.0`.

**Breaking Changes:**

- Delegate to the `LoadStrategy` for module information:
  - moduleId -> serverPath
  - serverPath -> moduleId

## 2.0.1

- Fix an issue where we would return prematurely during a `hotRestart`.
- Fix an issue where we would incorrectly fail if a `hotRestart` had to fall
  back to a full reload.

## 2.0.0

- Depend on the latest `package:vm_service` version `3.0.0+1`.

**Breaking Changes:**

- Now require a `LoadStrategy` to `Dwds.start`. This package defines two
  compatible load strategies, `RequireStrategy` and \`LegacyStrategy.
- `Dwds.start` function signature has been changed to accept one more parameter
  of new interface type `ExpressionCompiler` to support expression evaluation
- Provide an implementation of the `RequireStrategy` suitable for use with
  `package:build_runner`.
- Simplify hot reload logic and no longer provide module level hooks.

## 1.0.1

- Make the `root` optional for the `ProxyServerAssetReader`.

## 1.0.0

- Fix an issue where files imported with relative paths containing `../` may
  fail to resolve breakpoint locations.
- Remove dependency on `package:build_daemon`.
- Add `FrontendServerAssetReader` for use with Frontend Server builds.
- Depend on latest `package:sse` for handling client reconnects transparently on
  the server.
- Fix an issue where a failure to initiate debugging through the Dart Debug
  Extension would cause your development server to crash.
- Fix an issue where trying to launch DevTools in a non-debug enabled Chrome
  instance could crash your development server.

**Breaking Changes:**

- No longer use the `BuildResult` abstraction from `package:build_daemon` but
  require a similar abstraction provided by this package.
- `AssetHandler` has been renamed to `AssetReader` and no longer provides a
  generic resource handler. Specific methods for the required resources are now
  clearly defined. The new abstraction is now consumed through `dwds.dart`.
- `BuildRunnerAssetHandler` has been renamed to `ProxyServerAssetReader` and is
  now consumed through `dwds.dart`.

## 0.9.0

- Expose `middleware` and `handler`.

**Breaking Change:** The `AssetHandler` will not automatically be added the DWDS
handler cascade. You must now also add the `middleware` to your server's
pipeline.

## 0.8.5

- Always bind to `localhost` for the local debug workflow.
- Fix an issue where breakpoints could cause DevTools to hang.

## 0.8.4

- Support using WebSockets for the debug (VM Service) proxy by passing
  `useSseForDebugProxy: false` to `Dwds.start()`

## 0.8.3

- Support nesting Dart applications in iframes.

## 0.8.2

- Add the ability to receive events from the extension in batches.

## 0.8.1

- Depend on the latest `package:built_value`.

## 0.8.0

- Add temporary support for restoring breakpoints. Eventually the Dart VM
  protocol will clearly define how breakpoints should be restored.
- Depend on latest `package:sse` to get retry logic.
- Don't spawn DevTools if `serveDevTools` is false.
- `UrlEncoder` will also encode the base URI used by the injected client / Dart
  Debug Extension. \*\* Breaking Change \*\* `serveDevTools` is not
  automatically considered true if `enableDebugExtension`is true.

## 0.7.9

- Properly wait for hot reload to complete with the legacy module system.
- Fix issue with `getObject` for a class with a generic type.

## 0.7.8

- Support optional argument `urlEncoder` that is used to encode remote URLs for
  use with the Dart Debug Extension.

## 0.7.7

- Handle getObject for primitives properly.
- Properly black box scripts if query parameters are provided.

## 0.7.6

- Fix issue with source map logic for the legacy module system.
- Allow setting breakpoints multiple times and just return the old breakpoint.
- Fix a bug with Maps that contain lists of simple types.

## 0.7.5

- The injected client's connection is now based off the request URI.
- Fix an issue where resuming while paused at the start would cause an error.
- Expose the `ChromeDebugException` class for error handling purposes.
- Expose the `AppConnectionException` class for error handling purposes.
- DevTools will now launch immediately and lazily sets up necessary state.
- Properly set `pauseBreakpoints` on `kPauseBreakpoint` events.
- Greatly improves handling of List, Map and IdentityMap instances.
- Lazily parse source maps to improve performance for large applications.

## 0.7.4

- Deobfuscate DDC extension method stack traces.
- Properly get all libraries with the `legacy` module system.

## 0.7.3

- Correctly set `Isolate` state if debugging is initiated after the application
  has already started.

## 0.7.2

- Account for root directory path when using `package:` URIs with `DartUri`.

## 0.7.1

- Fix a bug where we would try to create a new isolate even for a failed hot
  restart. This created a race condition that would lead to a crash.
- Don't attempt to write a vm service request to a closed connection.
  - Instead we log a warning with the attempted request message and return.
- Make all `close` methods more robust by allowing them to be called more than
  once and returning the cached future from previous calls.
- Add explicit handling of app not loaded errors when handling chrome pause
  events.

## 0.7.0

- `DWDS.start` now requires an `AssetHandler` instead of `applicationPort`,
  `assetServerPort` and `applicationTarget`.
- Expose a `BuildRunnerAssetHandler` which proxies request to the asset server
  running within build runner.
- Support the Legacy Module strategy through the injected client.
- Support DDK sourcemap URIs.
- Update SDK dependency to minimum of 2.5.0.

### Bug Fixes:

- Fix handling of chrome pause events when we have no isolate loaded yet.

## 0.6.2

- Capture any errors that happen when handling SSE requests in the DevHandler
  and return an error response to the client code.
  - Log error responses in the client to the console.
- Handle empty Chrome exception descriptions.

## 0.6.1

- Add `isolateRef` to `Isolate`s `pauseEvent`s.
- Depend on the latest `package:vm_service`.
- Implements `invoke`.
- Adds support for VM object IDs for things that don't have Chrome object Ids
  (e.g. int, double, bool, null).

## 0.6.0

- Add new required parameter `enableDebugging` to `Dwds.start`. If `false` is
  provided, debug services will not run. However, reload logic will continue to
  work with the injected client.
- Handle injected client SSE errors.
- Handle a race condition when the browser is refreshed in the middle of setting
  up the debug services.

## 0.5.5

- Properly set the `pauseEvent` on the `Isolate`.
- Fix a race condition with Hot Restarts where the Isolate was not created in
  time for pause events.

## 0.5.4

- Fix issue where certain required fields of VM service protocol objects were
  null.
- Properly set the `exceptionPauseMode` on the `Isolate`.
- Depend on the latest `DevTools`.

## 0.5.3

- Fix issue where certain required fields of VM service protocol objects were
  null.

## 0.5.2

- Fix issue where certain required fields of VM service protocol objects were
  null.
- Properly display `Closure` names in the debug view.

## 0.5.1

- Fix an issue where missing source maps would cause a crash. A warning will now
  be logged to the console instead.
- Depend on the latest `package:webkit_inspection_protocol`.

## 0.5.0

- Fix an issue where we source map paths were not normalized.
- Added a check to tests for the variable DWDS_DEBUG_CHROME to run Chrome with a
  UI rather than headless.
- Catch unhandled errors in `client.js` and recommend using the
  `--no-injected-client` flag for webdev users.
- Add support for an SSE connection with Dart DevTools.
- Rename `wsUri` to `uri` on `DebugConnection` to reflect that the uri may not
  be a websocket.
- Depend on latest `package:vm_service`.

## 0.4.0

- Move `data` abstractions from `package:webdev` into `package:dwds`.
- Move debugging related handlers from `package:webdev` into `package:dwds`.
- Move injected client from `package:webdev` into `package:dwds`.
- Create new public entrypoint `dwds.dart`. Existing public API `services.dart`
  is now private.

## 0.3.3

- Add support for `getScript` for paused isolates.
- Add support for `onRequest` and `onResponse` listeners for the vm service.

## 0.3.2

- Add support for `scope` in `evaluate` calls.

## 0.3.1

- Improve error reporting for evals, give the full JS eval in the error message
  so it can be more easily reproduced.

## 0.3.0

- Change the exposed type on DebugService to VmServiceInterface

## 0.2.1

- Support `setExceptionPauseMode`.

## 0.2.0

- Added custom tokens to the `wsUri` for increased security.
  - Treating this as a breaking change because you now must use the `wsUri`
    getter to get a valid uri for connecting to the service, when previously
    combining the port and host was sufficient.

## 0.1.0

- Initial version
