// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* <GEN_DOC> */

import 'dart:async';
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

  String toString() {
    var kindName = wasmerExternKindName(kind);
    if (kind == WasmerExternKindFunction) {
      var runtime = WasmRuntime();
      var sig = WasmRuntime.getSignatureString("${moduleName}::${name}",
          runtime.getArgTypes(funcType), runtime.getReturnType(funcType));
      return "$kindName: $sig";
    } else {
      return "$kindName: ${moduleName}::${name}";
    }
  }
}

class WasmExportDescriptor {
  int kind;
  String name;
  Pointer<WasmerFunctype> funcType;
  WasmExportDescriptor(this.kind, this.name, this.funcType);

  String toString() {
    var kindName = wasmerExternKindName(kind);
    if (kind == WasmerExternKindFunction) {
      var runtime = WasmRuntime();
      var sig = WasmRuntime.getSignatureString(
          name, runtime.getArgTypes(funcType), runtime.getReturnType(funcType));
      return "$kindName: $sig";
    } else {
      return "$kindName: ${name}";
    }
  }
}

class WasmRuntime {
  static WasmRuntime? _inst;

  DynamicLibrary _lib;
  late Pointer<WasmerEngine> _engine;
/* <RUNTIME_MEMB> */

  factory WasmRuntime() {
    return _inst ??= WasmRuntime._init();
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

    return _checkNotEqual(modulePtr, nullptr, "Wasm module compile failed.");
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

  Pointer<WasmerInstance> instantiate(Pointer<WasmerStore> store,
      Pointer<WasmerModule> module, Pointer<Pointer<WasmerExtern>> imports) {
    return _checkNotEqual(_instance_new(store, module, imports, nullptr),
        nullptr, "Wasm module instantiation failed.");
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

  Pointer<WasmerExtern> functionToExtern(Pointer<WasmerFunc> func) {
    return _func_as_extern(func);
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

  Pointer<WasmerExtern> memoryToExtern(Pointer<WasmerMemory> memory) {
    return _memory_as_extern(memory);
  }

  Pointer<WasmerMemory> newMemory(
      Pointer<WasmerStore> store, int pages, int? maxPages) {
    var limPtr = allocate<WasmerLimits>();
    limPtr.ref.min = pages;
    limPtr.ref.max = maxPages ?? wasm_limits_max_default;
    var memType = _memorytype_new(limPtr);
    free(limPtr);
    return _checkNotEqual(
        _memory_new(store, memType), nullptr, "Failed to create memory.");
  }

  void growMemory(Pointer<WasmerMemory> memory, int deltaPages) {
    _checkNotEqual(
        _memory_grow(memory, deltaPages), 0, "Failed to grow memory.");
  }

  int memoryLength(Pointer<WasmerMemory> memory) {
    return _memory_size(memory);
  }

  Uint8List memoryView(Pointer<WasmerMemory> memory) {
    return _memory_data(memory).asTypedList(_memory_data_size(memory));
  }

  Pointer<WasmerFunc> newFunc(
      Pointer<WasmerStore> store,
      Pointer<WasmerFunctype> funcType,
      Pointer func,
      Pointer env,
      Pointer finalizer) {
    return _func_new_with_env(
        store, funcType, func.cast(), env.cast(), finalizer.cast());
  }

  Pointer<WasmerWasiConfig> newWasiConfig() {
    var name = allocate<Uint8>();
    name[0] = 0;
    var config = _wasi_config_new(name);
    free(name);
    return _checkNotEqual(config, nullptr, "Failed to create WASI config.");
  }

  void captureWasiStdout(Pointer<WasmerWasiConfig> config) {
    _wasi_config_inherit_stdout(config);
  }

  void captureWasiStderr(Pointer<WasmerWasiConfig> config) {
    _wasi_config_inherit_stderr(config);
  }

  Pointer<WasmerWasiEnv> newWasiEnv(Pointer<WasmerWasiConfig> config) {
    return _checkNotEqual(
        _wasi_env_new(config), nullptr, "Failed to create WASI environment.");
  }

  void wasiEnvSetMemory(
      Pointer<WasmerWasiEnv> env, Pointer<WasmerMemory> memory) {
    _wasi_env_set_memory(env, memory);
  }

  void getWasiImports(Pointer<WasmerStore> store, Pointer<WasmerModule> mod,
      Pointer<WasmerWasiEnv> env, Pointer<Pointer<WasmerExtern>> imports) {
    _checkNotEqual(_wasi_get_imports(store, mod, env, imports), 0,
        "Failed to fill WASI imports.");
  }

  Stream<List<int>> getWasiStdoutStream(Pointer<WasmerWasiEnv> env) {
    return Stream.fromIterable(_WasiStreamIterable(env, _wasi_env_read_stdout));
  }

  Stream<List<int>> getWasiStderrStream(Pointer<WasmerWasiEnv> env) {
    return Stream.fromIterable(_WasiStreamIterable(env, _wasi_env_read_stderr));
  }

  String _getLastError() {
    var length = _wasmer_last_error_length();
    var buf = allocate<Uint8>(count: length);
    _wasmer_last_error_message(buf, length);
    String message = utf8.decode(buf.asTypedList(length));
    free(buf);
    return message;
  }

  T _checkNotEqual<T>(T x, T y, String errorMessage) {
    if (x == y) {
      throw Exception("$errorMessage\n${_getLastError()}");
    }
    return x;
  }

  static String getSignatureString(
      String name, List<int> argTypes, int returnType) {
    return "${wasmerValKindName(returnType)} $name" +
        "(${argTypes.map(wasmerValKindName).join(", ")})";
  }
}

class _WasiStreamIterator implements Iterator<List<int>> {
  static final int _bufferLength = 1024;
  Pointer<WasmerWasiEnv> _env;
  Function _reader;
  Pointer<Uint8> _buf = allocate<Uint8>(count: _bufferLength);
  int _length = 0;
  _WasiStreamIterator(this._env, this._reader) {}

  bool moveNext() {
    _length = _reader(_env, _buf, _bufferLength);
    return true;
  }

  List<int> get current => _buf.asTypedList(_length);
}

class _WasiStreamIterable extends Iterable<List<int>> {
  Pointer<WasmerWasiEnv> _env;
  Function _reader;
  _WasiStreamIterable(this._env, this._reader) {}
  @override
  Iterator<List<int>> get iterator => _WasiStreamIterator(_env, _reader);
}
