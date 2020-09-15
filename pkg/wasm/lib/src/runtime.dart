// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'wasmer_api.dart';

class WasmRuntime {
  static WasmRuntime _inst;

  DynamicLibrary _lib;
  WasmerCompileFn _compile;
  WasmerInstantiateFn _instantiate;
  WasmerInstanceExportsFn _instance_exports;
  WasmerExportsLenFn _exports_len;
  WasmerExportsGetFn _exports_get;
  WasmerExportKindFn _export_kind;
  WasmerExportToFuncFn _export_to_func;
  WasmerExportFuncReturnsArityFn _export_func_returns_arity;
  WasmerExportFuncReturnsFn _export_func_returns;
  WasmerExportFuncParamsArityFn _export_func_params_arity;
  WasmerExportFuncParamsFn _export_func_params;
  WasmerExportFuncCallFn _export_func_call;

  factory WasmRuntime() {
    if (_inst == null) {
      _inst = WasmRuntime._init();
    }
    return _inst;
  }

  static String _getLibName() {
    if (Platform.isMacOS) return "libwasmer.dylib";
    if (Platform.isLinux) return "libwasmer.so";
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

  WasmRuntime._init() {
    var libPath = path.join(_getLibDir(), _getLibName());
    _lib = DynamicLibrary.open(libPath);
    _compile = _lib.lookupFunction<NativeWasmerCompileFn, WasmerCompileFn>(
        'wasmer_compile');
    _instantiate =
        _lib.lookupFunction<NativeWasmerInstantiateFn, WasmerInstantiateFn>(
            'wasmer_module_instantiate');
    _instance_exports = _lib.lookupFunction<NativeWasmerInstanceExportsFn,
        WasmerInstanceExportsFn>('wasmer_instance_exports');
    _exports_len =
        _lib.lookupFunction<NativeWasmerExportsLenFn, WasmerExportsLenFn>(
            'wasmer_exports_len');
    _exports_get =
        _lib.lookupFunction<NativeWasmerExportsGetFn, WasmerExportsGetFn>(
            'wasmer_exports_get');
    _export_kind =
        _lib.lookupFunction<NativeWasmerExportKindFn, WasmerExportKindFn>(
            'wasmer_export_kind');
    _export_to_func =
        _lib.lookupFunction<NativeWasmerExportToFuncFn, WasmerExportToFuncFn>(
            'wasmer_export_to_func');
    _export_func_returns_arity = _lib.lookupFunction<
        NativeWasmerExportFuncReturnsArityFn,
        WasmerExportFuncReturnsArityFn>('wasmer_export_func_returns_arity');
    _export_func_returns = _lib.lookupFunction<NativeWasmerExportFuncReturnsFn,
        WasmerExportFuncReturnsFn>('wasmer_export_func_returns');
    _export_func_params_arity = _lib.lookupFunction<
        NativeWasmerExportFuncParamsArityFn,
        WasmerExportFuncParamsArityFn>('wasmer_export_func_params_arity');
    _export_func_params = _lib.lookupFunction<NativeWasmerExportFuncParamsFn,
        WasmerExportFuncParamsFn>('wasmer_export_func_params');
    _export_func_call = _lib.lookupFunction<NativeWasmerExportFuncCallFn,
        WasmerExportFuncCallFn>('wasmer_export_func_call');
  }

  Pointer<WasmerModule> compile(Uint8List data) {
    var dataPtr = allocate<Uint8>(count: data.length);
    for (int i = 0; i < data.length; ++i) {
      dataPtr[i] = data[i];
    }

    var modulePtrPtr = allocate<Pointer<WasmerModule>>();
    int result = _compile(modulePtrPtr, dataPtr, data.length);
    Pointer<WasmerModule> modulePtr = modulePtrPtr.value;

    free(modulePtrPtr);
    free(dataPtr);

    if (result != WasmerResultOk) {
      throw Exception("Wasm module compile failed");
    }

    return modulePtr;
  }

  Pointer<WasmerInstance> instantiate(Pointer<WasmerModule> module,
      Pointer<WasmerImport> imports, int numImports) {
    var instancePtrPtr = allocate<Pointer<WasmerInstance>>();
    int result = _instantiate(module, instancePtrPtr, imports, numImports);
    Pointer<WasmerInstance> instancePtr = instancePtrPtr.value;
    free(instancePtrPtr);

    if (result != WasmerResultOk) {
      throw Exception("Wasm module instantiation failed");
    }

    return instancePtr;
  }

  List<Pointer<WasmerExport>> exports(Pointer<WasmerInstance> instancePtr) {
    var exportsPtrPtr = allocate<Pointer<WasmerExports>>();
    _instance_exports(instancePtr, exportsPtrPtr);
    Pointer<WasmerExports> exportsPtr = exportsPtrPtr.value;
    free(exportsPtrPtr);

    var n = _exports_len(exportsPtr);
    var exps = <Pointer<WasmerExport>>[];
    for (var i = 0; i < n; ++i) {
      exps.add(_exports_get(exportsPtr, i));
    }
    return exps;
  }

  int exportKind(Pointer<WasmerExport> export) {
    return _export_kind(export);
  }

  Pointer<WasmerExportFunc> exportToFunction(Pointer<WasmerExport> export) {
    return _export_to_func(export);
  }

  List<int> getArgTypes(Pointer<WasmerExportFunc> func) {
    var types = <int>[];
    var nPtr = allocate<Uint32>();
    var result = _export_func_params_arity(func, nPtr);
    if (result != WasmerResultOk) {
      free(nPtr);
      throw Exception("Failed to get number of WASM function args");
    }
    var n = nPtr.value;
    free(nPtr);
    var argsPtr = allocate<Uint32>(count: n);
    result = _export_func_params(func, argsPtr, n);
    if (result != WasmerResultOk) {
      free(argsPtr);
      throw Exception("Failed to get WASM function args");
    }
    for (var i = 0; i < n; ++i) {
      types.add(argsPtr[i]);
    }
    free(argsPtr);
    return types;
  }

  int getReturnType(Pointer<WasmerExportFunc> func) {
    var nPtr = allocate<Uint32>();
    var result = _export_func_returns_arity(func, nPtr);
    if (result != WasmerResultOk) {
      free(nPtr);
      throw Exception("Failed to get number of WASM function returns");
    }
    var n = nPtr.value;
    free(nPtr);
    if (n == 0) {
      return WasmerValueTagVoid;
    } else if (n > 1) {
      throw Exception("Multiple return values are not supported");
    }
    var returnsPtr = allocate<Uint32>();
    result = _export_func_params(func, returnsPtr, 1);
    if (result != WasmerResultOk) {
      free(returnsPtr);
      throw Exception("Failed to get WASM function args");
    }
    var type = returnsPtr.value;
    free(returnsPtr);
    return type;
  }

  void call(Pointer<WasmerExportFunc> func, Pointer<WasmerValue> args,
      int numArgs, Pointer<WasmerValue> results, int numResults) {
    var result = _export_func_call(func, args, numArgs, results, numArgs);
    if (result != WasmerResultOk) {
      throw Exception("Failed to call WASM function");
    }
  }
}
