## Detecting whether code is running as WebAssembly

`dart2wasm` defines `dart.tool.dart2wasm` as `true`, meaning that `bool.fromEnvironment('dart.tool.dart2wasm')` can be used in a constant context to determine whether it was
compiled to WebAssembly.
