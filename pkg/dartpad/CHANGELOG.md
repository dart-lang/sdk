## v0.1.4
 - Bundle `cupertino_icons` when running `dart run dartpad setup flutter`.

## v0.1.3
 - Support the `kernel/ddc/canary/dart_sdk.js` layout in `flutter_web_sdk` when
   running `dart run dartpad setup flutter`.

## v0.1.2
 - Support loading Flutter assets from the workspace and dependency packages.
 - Retain Git history when cloning Flutter in `dart run dartpad setup flutter --channel`.

## v0.1.1
 - Add `DartPadSdk.sharedWorker` and `dart run dartpad setup shared-worker` CLI
   subcommand for running DartPad inside a `SharedWorker`.
 - Add `Sandbox.connectServiceProtocol`, `Sandbox.startServiceProtocol`, and
   `DartPadSdk.createDevToolsIframe` (`DevToolsIframe`) for VM Service and
   embedded DevTools support (replacing `Sandbox.invokeExtension` and
   `Sandbox.extensionEvents`).
 - Add `ConsoleLevel` to `Sandbox.console` and fold `Sandbox.errors` and
   `Sandbox.unhandledRejections` into `ConsoleLevel.error`.
 - Add `WorkerClient.version()` (`VersionInfo`), `WorkerClient.ping()`, and
   `abort` support on `DartPadSdk.dedicatedWorker` and `DartPadSdk.sharedWorker`.
 - Replace `Uri` parameters/fields with `String` workspace paths across
   `Workspace`, `Sandbox`, `FileChangeEvent`, and `DartPadRunMode`.
 - Standardize resource cleanup methods to `close()` across all client types and
   clean up child streams automatically on disconnect.
 - Strip request headers in embedded `pub` that trigger CORS preflight requests
   in Firefox and Safari.

## v0.0.10
 - Add `dart run dartpad setup` CLI (`dart` and `flutter` subcommands) to
   download or build DartPad SDK assets.
 - Stop bundling prebuilt `web/` assets inside the published package archive.
 - Pre-populate `/pub-cache` in the Flutter DartPad SDK `sdk.tar` so `pub get`
   does not need to download precompiled packages.

## v0.0.9
 - Add missing `MessagePort` VM compilation stubs (`asTransferableMessagePort`
   and `fromMessagePort`).

## v0.0.8
 - Precompile and pin `package:material_ui`, `package:cupertino_ui`, and hosted
   dependencies in the Flutter DartPad SDK.
 - Load CanvasKit from Google CDN (`www.gstatic.com/flutter-canvaskit/`) and
   trim unused files from `sdk.tar`.

## v0.0.7
 - Dart stack traces printed from a sandbox are now mapped back to Dart source
   locations instead of rendering as raw JavaScript frames.
 - Fix stale hardcoded SDK `platformVersion` in the embedded `pub` tool.
 - The Flutter DartPad SDK can now build its web SDK from this SDK's sources,
   instead of copying the one Flutter pins.

## v0.0.6
 - Provide `Sandbox.run(entrypoint, mode)` for configuring different run modes.
 - Simplifies embedding by introducing `SandboxedIframe` that manages `MessagePort`s directly.
 - Faster binary data transfer over sandbox message ports using `Uint8List`.
 - Fix race condition during language server shutdown.

## v0.0.5
 - Update embedded resources.

## v0.0.4
 - Support for file watching.
 - `flutter_test` SDK-package is now included in the Flutter DartPad SDK.

## v0.0.3
 - Embed assets for `package:dartpad` in `web/` folder.

## v0.0.2
 - Fixed dependency constraints on `package:web`.

## v0.0.1
 - Initial preview release.
