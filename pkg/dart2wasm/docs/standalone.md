# Standalone mode

By default, dart2wasm generates WebAssembly modules meant to run on platforms
with JavaScript support (mainly, browsers).
Both the SDK and application code can rely on `dart:js_interop` libraries to
access external JavaScript APIs.

For WebAssembly targets without a JavaScript engine (like wasmtime or similar
runtimes), dart2wasm supports a standalone target too. This target is enabled
with the `--standalone` compiler flag, and makes `dart:js_interop` unavailable.

Even in standalone mode, the SDK needs host imports for functionality like
timers, stack traces, regular expressions, `dart:math` or number formatting.
These imports are referenced in [this file](https://github.com/dart-lang/sdk/blob/main/sdk/lib/_internal/wasm/standalone/embedder.dart).
Note that these imports are not stable, and might change in future Dart
versions.

Additional definitions can be imported via [imports and exports](./imports_and_exports.md).

## Running standalone modules

There are two plausible ways to run standalone modules:

1. By using APIs from a WebAssembly engine to define definitions for imports in
   native code. There is no example for this in the SDK, but test definitions
   for browser tests (`dart2WasmStandaloneHtml` in `pkg/test_runner/lib/src/browser.dart`)
   might help as a starting point.
2. By re-implementing a subset of imports in WebAssembly, and then using tools
   like `wasm-merge` from Binaryen to link two modules into a module with fewer
   or no dependencies. Implementing Dart imports by delegating to WASI
   definitions would allow running these modules without custom native imports,
   for example.

Examples for both options are discussed in the [tracking issue](https://github.com/dart-lang/sdk/issues/53884).
