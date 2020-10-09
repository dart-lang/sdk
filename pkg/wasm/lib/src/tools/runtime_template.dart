// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* <GEN_DOC> */

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'wasmer_api.dart';

class WasmImportDescriptor {
  int kind;
  String moduleName;
  String name;
  Pointer<WasmerFunctype> funcType;
  WasmImportDescriptor(this.kind, this.moduleName, this.name, this.funcType);
}

class WasmExportDescriptor {
  int kind;
  String name;
  Pointer<WasmerFunctype> funcType;
  WasmExportDescriptor(this.kind, this.name, this.funcType);
}

class WasmRuntime {
  static WasmRuntime? _inst;

  DynamicLibrary _lib;
  late Pointer<WasmerEngine> _engine;
/* <RUNTIME_MEMB> */

  factory WasmRuntime() {
    WasmRuntime inst = _inst ?? WasmRuntime._init();
    _inst = inst;
    return inst;
  }

  static String _getLibName() {
    if (Platform.isMacOS) return "libwasmer.dylib";
    if (Platform.isLinux) return "libwasmer.so";
    // TODO(dartbug.com/37882): Support more platforms.
    throw Exception("Wasm not currently supported on this platform");
  }

  static String _getLibDir() {
    // The common case, and how cli_util.dart computes the Dart SDK directory,
    // path.dirname called twice on Platform.resolvedExecutable.
    var commonLibDir = path.join(
        path.absolute(path.dirname(path.dirname(Platform.resolvedExecutable))),
        'bin',
        'third_party',
        'wasmer');
    if (Directory(commonLibDir).existsSync()) {
      return commonLibDir;
    }

    // This is the less common case where the user is in the checked out Dart
    // SDK, and is executing dart via:
    // ./out/ReleaseX64/dart ...
    var checkedOutLibDir = path.join(
        path.absolute(path.dirname(Platform.resolvedExecutable)),
        'dart-sdk',
        'bin',
        'third_party',
        'wasmer');
    if (Directory(checkedOutLibDir).existsSync()) {
      return checkedOutLibDir;
    }

    // If neither returned above, we return the common case:
    return commonLibDir;
  }

  WasmRuntime._init()
      : _lib = DynamicLibrary.open(path.join(_getLibDir(), _getLibName())) {
/* <RUNTIME_LOAD> */

    _engine = _engine_new();
  }

  Pointer<WasmerStore> newStore() {
    return _store_new(_engine);
  }

  Pointer<WasmerModule> compile(Pointer<WasmerStore> store, Uint8List data) {
    var dataPtr = allocate<Uint8>(count: data.length);
    for (int i = 0; i < data.length; ++i) {
      dataPtr[i] = data[i];
    }
    var dataVec = allocate<WasmerByteVec>();
    dataVec.ref.data = dataPtr;
    dataVec.ref.length = data.length;

    var modulePtr = _module_new(store, dataVec);

    free(dataPtr);
    free(dataVec);

    if (modulePtr == nullptr) {
      throw Exception("Wasm module compile failed");
    }

    return modulePtr;
  }

  List<WasmExportDescriptor> exportDescriptors(Pointer<WasmerModule> module) {
    var exportsVec = allocate<WasmerExporttypeVec>();
    _module_exports(module, exportsVec);
    var exps = <WasmExportDescriptor>[];
    for (var i = 0; i < exportsVec.ref.length; ++i) {
      var exp = exportsVec.ref.data[i];
      var extern = _exporttype_type(exp);
      var kind = _externtype_kind(extern);
      var fnType = kind == WasmerExternKindFunction
          ? _externtype_as_functype(extern)
          : nullptr;
      exps.add(WasmExportDescriptor(
          kind, _exporttype_name(exp).ref.toString(), fnType));
    }
    free(exportsVec);
    return exps;
  }

  List<WasmImportDescriptor> importDescriptors(Pointer<WasmerModule> module) {
    var importsVec = allocate<WasmerImporttypeVec>();
    _module_imports(module, importsVec);
    var imps = <WasmImportDescriptor>[];
    for (var i = 0; i < importsVec.ref.length; ++i) {
      var imp = importsVec.ref.data[i];
      var extern = _importtype_type(imp);
      var kind = _externtype_kind(extern);
      var fnType = kind == WasmerExternKindFunction
          ? _externtype_as_functype(extern)
          : nullptr;
      imps.add(WasmImportDescriptor(
          kind,
          _importtype_module(imp).ref.toString(),
          _importtype_name(imp).ref.toString(),
          fnType));
    }
    free(importsVec);
    return imps;
  }

  Pointer<WasmerInstance> instantiate(
      Pointer<WasmerStore> store,
      Pointer<WasmerModule> module,
      Pointer<Pointer<WasmerExtern>> imports,
      int numImports) {
    var importsVec = allocate<WasmerImporttypeVec>();
    _module_imports(module, importsVec);
    if (importsVec.ref.length != numImports) {
      throw Exception(
          "Wrong number of imports. Expected ${importsVec.ref.length} but " +
              "found $numImports.");
    }
    free(importsVec);

    var instancePtr = _instance_new(store, module, imports, nullptr);
    if (instancePtr == nullptr) {
      throw Exception("Wasm module instantiation failed");
    }

    return instancePtr;
  }

  Pointer<WasmerExternVec> exports(Pointer<WasmerInstance> instancePtr) {
    var exports = allocate<WasmerExternVec>();
    _instance_exports(instancePtr, exports);
    return exports;
  }

  int externKind(Pointer<WasmerExtern> extern) {
    return _extern_kind(extern);
  }

  Pointer<WasmerFunc> externToFunction(Pointer<WasmerExtern> extern) {
    return _extern_as_func(extern);
  }

  List<int> getArgTypes(Pointer<WasmerFunctype> funcType) {
    var types = <int>[];
    var args = _functype_params(funcType);
    for (var i = 0; i < args.ref.length; ++i) {
      types.add(_valtype_kind(args.ref.data[i]));
    }
    return types;
  }

  int getReturnType(Pointer<WasmerFunctype> funcType) {
    var rets = _functype_results(funcType);
    if (rets.ref.length == 0) {
      return WasmerValKindVoid;
    } else if (rets.ref.length > 1) {
      throw Exception("Multiple return values are not supported");
    }
    return _valtype_kind(rets.ref.data[0]);
  }

  void call(Pointer<WasmerFunc> func, Pointer<WasmerVal> args,
      Pointer<WasmerVal> results) {
    _func_call(func, args, results);
  }

  Pointer<WasmerMemory> externToMemory(Pointer<WasmerExtern> extern) {
    return _extern_as_memory(extern);
  }

  Pointer<WasmerMemory> newMemory(
      Pointer<WasmerStore> store, int pages, int? maxPages) {
    var limPtr = allocate<WasmerLimits>();
    limPtr.ref.min = pages;
    limPtr.ref.max = maxPages ?? wasm_limits_max_default;
    var memType = _memorytype_new(limPtr);
    free(limPtr);
    Pointer<WasmerMemory> memPtr = _memory_new(store, memType);

    if (memPtr == nullptr) {
      throw Exception("Failed to create memory");
    }
    return memPtr;
  }

  void growMemory(Pointer<WasmerMemory> memory, int deltaPages) {
    var result = _memory_grow(memory, deltaPages);
    if (result == 0) {
      throw Exception("Failed to grow memory");
    }
  }

  int memoryLength(Pointer<WasmerMemory> memory) {
    return _memory_size(memory);
  }

  Uint8List memoryView(Pointer<WasmerMemory> memory) {
    return _memory_data(memory).asTypedList(_memory_data_size(memory));
  }
}
