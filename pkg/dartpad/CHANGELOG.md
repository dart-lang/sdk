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
