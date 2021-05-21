# wasm

This package provides utilities for loading and running WASM modules. It is
built on top of the [Wasmer](https://github.com/wasmerio/wasmer) runtime.

## Setup

Run `dart bin/setup.dart` to build the Wasmer runtime.

## Basic Usage

As a simple example, we'll try to call the following C function from Dart using
`package:wasm`. For a more detailed example that uses WASI, check out the
example directory.

```c++
extern "C" int square(int n) { return n * n; }
```

We can compile this C++ code to WASM using a recent version of clang:

```bash
clang --target=wasm32 -nostdlib -Wl,--export-all -Wl,--no-entry -o square.wasm square.cc
```

Then we can load and run it like this:

```dart
import "dart:io";
import "package:wasm/wasm.dart";

void main() {
  final data = File("square.wasm").readAsBytesSync();
  final mod = WasmModule(data);
  print(mod.describe());
  final inst = mod.instantiate().build();
  final square = inst.lookupFunction("square");
  print(square(12));
}
```

This should print:

```
export memory: memory
export function: int32 square(int32)

144
```
