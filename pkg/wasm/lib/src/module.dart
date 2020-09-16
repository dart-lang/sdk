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
  Pointer<WasmerModule> _module;

  /// Compile a module.
  WasmModule(Uint8List data) {
    _module = WasmRuntime().compile(data);
  }

  /// Instantiate the module with the given imports.
  WasmInstance instantiate(WasmImports imports) {
    return WasmInstance(_module, imports);
  }

  /// Returns a description of all of the module's imports and exports, for
  /// debugging.
  String describe() {
    var description = StringBuffer();
    var runtime = WasmRuntime();
    var imports = runtime.importDescriptors(_module);
    for (var imp in imports) {
      var kind = wasmerImpExpKindName(imp.kind);
      description.write('import $kind: ${imp.moduleName}::${imp.name}\n');
    }
    var exports = runtime.exportDescriptors(_module);
    for (var exp in exports) {
      var kind = wasmerImpExpKindName(exp.kind);
      description.write('export $kind: ${exp.name}\n');
    }
    return description.toString();
  }
}

/// WasmImports holds all the imports for a WasmInstance.
class WasmImports {
  Pointer<WasmerImport> _imports;
  int _capacity;
  int _length;

  /// Create an imports object.
  WasmImports([this._capacity = 4]) : _length = 0 {
    _imports = allocate<WasmerImport>(count: this._capacity);
  }

  /// Returns the number of imports.
  int get length => _length;
}

/// WasmInstance is an instantiated WasmModule.
class WasmInstance {
  Pointer<WasmerModule> _module;
  Pointer<WasmerInstance> _instance;
  Map<String, WasmFunction> _functions;

  WasmInstance(this._module, WasmImports imports) {
    var runtime = WasmRuntime();
    _instance = runtime.instantiate(_module, imports._imports, imports.length);
    _functions = {};
    var exps = runtime.exports(_instance);
    for (var e in exps) {
      var kind = runtime.exportKind(e);
      String name = runtime.exportName(e);
      if (kind == WasmerImpExpKindFunction) {
        var f = runtime.exportToFunction(e);
        _functions[name] = WasmFunction(
            name, f, runtime.getArgTypes(f), runtime.getReturnType(f));
      }
    }
  }

  /// Searches the instantiated module for the given function. Returns null if
  /// it is not found.
  dynamic lookupFunction(String name) {
    return _functions[name];
  }
}
