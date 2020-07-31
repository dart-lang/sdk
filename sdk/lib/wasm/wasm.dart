// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// {@category VM}
/// {@nodoc}
library dart.wasm;

import 'dart:typed_data';

// Represents the WASM 32-bit int type.
class Int32 {}

// Represents the WASM 64-bit int type.
class Int64 {}

// Represents the WASM 32-bit float type.
class Float {}

// Represents the WASM 64-bit float type.
class Double {}

// Represents the return type of a void function in WASM.
class Void {}

// WasmModule is a compiled module that can be instantiated.
abstract class WasmModule {
  // Compile a module.
  external factory WasmModule(Uint8List data);

  // Instantiate the module with the given imports.
  WasmInstance instantiate(WasmImports imports);

  // Describes the imports and exports that the module expects, for debugging.
  String describe();
}

// WasmImports holds all the imports for a WasmInstance.
abstract class WasmImports {
  // Create an imports object.
  external factory WasmImports();

  // Add a global variable to the imports.
  void addGlobal<T>(String moduleName, String name, num value, bool mutable);

  // Add a memory to the imports.
  void addMemory(String moduleName, String name, WasmMemory memory);

  // Add a function to the imports.
  void addFunction<T extends Function>(
      String moduleName, String name, Function fn);
}

// WasmMemory is a sandbox for a WasmInstance to run in.
abstract class WasmMemory {
  // Create a new memory with the given number of initial pages, and optional
  // maximum number of pages.
  external factory WasmMemory(int initialPages, [int? maxPages]);

  // The WASM spec defines the page size as 64KiB.
  static const int kPageSizeInBytes = 64 * 1024;

  // Returns the length of the memory in pages.
  int get lengthInPages;

  // Returns the length of the memory in bytes.
  int get lengthInBytes;

  // Returns the byte at the given index.
  int operator [](int index);

  // Sets the byte at the iven index to value.
  void operator []=(int index, int value);

  // Grow the memory by deltaPages. Returns the number of pages before resizing.
  int grow(int deltaPages);
}

// WasmInstance is an instantiated WasmModule.
abstract class WasmInstance {
  // Find an exported function with the given signature.
  WasmFunction<T> lookupFunction<T extends Function>(String name);

  // Returns this instance's memory.
  WasmMemory get memory;
}

// WasmFunction is a callable function in a WasmInstance.
abstract class WasmFunction<T extends Function> {
  num call(List<num> args);
}
