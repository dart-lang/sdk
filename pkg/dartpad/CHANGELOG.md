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
