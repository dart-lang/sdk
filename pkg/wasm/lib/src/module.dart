// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'runtime.dart';
import 'function.dart';
import 'wasmer_api.dart';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

/// WasmModule is a compiled module that can be instantiated.
class WasmModule {
  Pointer<WasmerStore> _store;
  late Pointer<WasmerModule> _module;

  /// Compile a module.
  WasmModule(Uint8List data) : _store = WasmRuntime().newStore() {
    _module = WasmRuntime().compile(_store, data);
  }

  /// Instantiate the module with the given imports.
  WasmInstance instantiate(WasmImports imports) {
    return WasmInstance(_store, _module, imports);
  }

  /// Create a new memory with the given number of initial pages, and optional
  /// maximum number of pages.
  WasmMemory createMemory(int pages, [int? maxPages]) {
    return WasmMemory._create(_store, pages, maxPages);
  }

  /// Returns a description of all of the module's imports and exports, for
  /// debugging.
  String describe() {
    var description = StringBuffer();
    var runtime = WasmRuntime();
    var imports = runtime.importDescriptors(_module);
    for (var imp in imports) {
      var kind = wasmerExternKindName(imp.kind);
      description.write('import $kind: ${imp.moduleName}::${imp.name}\n');
    }
    var exports = runtime.exportDescriptors(_module);
    for (var exp in exports) {
      var kind = wasmerExternKindName(exp.kind);
      description.write('export $kind: ${exp.name}\n');
    }
    return description.toString();
  }
}

/// WasmImports holds all the imports for a WasmInstance.
class WasmImports {
  Pointer<Pointer<WasmerExtern>> _imports;
  int _capacity;
  int _length;

  /// Create an imports object.
  WasmImports([this._capacity = 4])
      : _imports = allocate<Pointer<WasmerExtern>>(count: _capacity),
        _length = 0 {}

  /// Returns the number of imports.
  int get length => _length;
}

/// WasmInstance is an instantiated WasmModule.
class WasmInstance {
  Pointer<WasmerStore> _store;
  Pointer<WasmerModule> _module;
  Pointer<WasmerInstance> _instance;
  Pointer<WasmerMemory>? _exportedMemory;
  Map<String, WasmFunction> _functions = {};

  WasmInstance(this._store, this._module, WasmImports imports)
      : _instance = WasmRuntime()
            .instantiate(_store, _module, imports._imports, imports.length) {
    var runtime = WasmRuntime();
    var exports = runtime.exports(_instance);
    var exportDescs = runtime.exportDescriptors(_module);
    assert(exports.ref.length == exportDescs.length);
    for (var i = 0; i < exports.ref.length; ++i) {
      var e = exports.ref.data[i];
      var kind = runtime.externKind(exports.ref.data[i]);
      String name = exportDescs[i].name;
      if (kind == WasmerExternKindFunction) {
        var f = runtime.externToFunction(e);
        var ft = exportDescs[i].funcType;
        _functions[name] = WasmFunction(
            name, f, runtime.getArgTypes(ft), runtime.getReturnType(ft));
      } else if (kind == WasmerExternKindMemory) {
        // WASM currently allows only one memory per module.
        _exportedMemory = runtime.externToMemory(e);
      }
    }
  }

  /// Searches the instantiated module for the given function. Returns null if
  /// it is not found.
  dynamic lookupFunction(String name) {
    return _functions[name];
  }

  /// Returns the memory exported from this instance.
  WasmMemory get memory {
    if (_exportedMemory == null) {
      throw Exception("Wasm module did not export its memory.");
    }
    return WasmMemory._fromExport(_exportedMemory as Pointer<WasmerMemory>);
  }
}

/// WasmMemory contains the memory of a WasmInstance.
class WasmMemory {
  Pointer<WasmerMemory> _mem;
  late Uint8List _view;

  WasmMemory._fromExport(this._mem) {
    _view = WasmRuntime().memoryView(_mem);
  }

  /// Create a new memory with the given number of initial pages, and optional
  /// maximum number of pages.
  WasmMemory._create(Pointer<WasmerStore> store, int pages, int? maxPages)
      : _mem = WasmRuntime().newMemory(store, pages, maxPages) {
    _view = WasmRuntime().memoryView(_mem);
  }

  /// The WASM spec defines the page size as 64KiB.
  static const int kPageSizeInBytes = 64 * 1024;

  /// Returns the length of the memory in pages.
  int get lengthInPages {
    return WasmRuntime().memoryLength(_mem);
  }

  /// Returns the length of the memory in bytes.
  int get lengthInBytes => _view.lengthInBytes;

  /// Returns the byte at the given index.
  int operator [](int index) => _view[index];

  /// Sets the byte at the given index to value.
  void operator []=(int index, int value) {
    _view[index] = value;
  }

  /// Grow the memory by deltaPages.
  void grow(int deltaPages) {
    var runtime = WasmRuntime();
    runtime.growMemory(_mem, deltaPages);
    _view = runtime.memoryView(_mem);
  }
}
