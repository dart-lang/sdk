## 1.2.0

- Added `DartInitializeRequestArguments`, a subclass of `InitializeRequestArguments` that supports a custom flag `supportsDartUris` for informing the debug adapter that the client supports using URIs in places that might usually be file paths (such as `stackTraceRequest`). Setting this flag indicates that the client supports `file:` URIs _and also_ any custom-scheme URIs whose content can be provided by the analysis server from the matching Dart SDK.

## 1.1.0

- Updated all generated classes using the latest published version of the DAP spec.

## 1.0.0

- Moved DAP classes from `package:dds` into a standalone package.
