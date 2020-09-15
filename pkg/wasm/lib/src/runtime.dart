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

class WasmImportDescriptor {
  int kind;
  String moduleName;
  String name;
  WasmImportDescriptor(this.kind, this.moduleName, this.name);
}

class WasmExportDescriptor {
  int kind;
  String name;
  WasmExportDescriptor(this.kind, this.name);
}

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
  WasmerExportNamePtrFn _export_name_ptr;
  WasmerExportDescriptorsFn _export_descriptors;
  WasmerExportDescriptorsDestroyFn _export_descriptors_destroy;
  WasmerExportDescriptorsLenFn _export_descriptors_len;
  WasmerExportDescriptorsGetFn _export_descriptors_get;
  WasmerExportDescriptorKindFn _export_descriptor_kind;
  WasmerExportDescriptorNamePtrFn _export_descriptor_name_ptr;
  WasmerImportDescriptorModuleNamePtrFn _import_descriptor_module_name_ptr;
  WasmerImportDescriptorNamePtrFn _import_descriptor_name_ptr;
  WasmerImportDescriptorsFn _import_descriptors;
  WasmerImportDescriptorsDestroyFn _import_descriptors_destroy;
  WasmerImportDescriptorsLenFn _import_descriptors_len;
  WasmerImportDescriptorsGetFn _import_descriptors_get;
  WasmerImportDescriptorKindFn _import_descriptor_kind;

  factory WasmRuntime() {
    if (_inst == null) {
      _inst = WasmRuntime._init();
    }
    return _inst;
  }

  static String _getLibName() {
    if (Platform.isMacOS) return "libwasmer_wrapper.dylib";
    if (Platform.isLinux) return "libwasmer_wrapper.so";
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
    _export_descriptors = _lib.lookupFunction<NativeWasmerExportDescriptorsFn,
        WasmerExportDescriptorsFn>('wasmer_export_descriptors');
    _export_descriptors_destroy = _lib.lookupFunction<
        NativeWasmerExportDescriptorsDestroyFn,
        WasmerExportDescriptorsDestroyFn>('wasmer_export_descriptors_destroy');
    _export_descriptors_len = _lib.lookupFunction<
        NativeWasmerExportDescriptorsLenFn,
        WasmerExportDescriptorsLenFn>('wasmer_export_descriptors_len');
    _export_descriptors_get = _lib.lookupFunction<
        NativeWasmerExportDescriptorsGetFn,
        WasmerExportDescriptorsGetFn>('wasmer_export_descriptors_get');
    _export_descriptor_kind = _lib.lookupFunction<
        NativeWasmerExportDescriptorKindFn,
        WasmerExportDescriptorKindFn>('wasmer_export_descriptor_kind');
    _export_name_ptr =
        _lib.lookupFunction<NativeWasmerExportNamePtrFn, WasmerExportNamePtrFn>(
            'wasmer_export_name_ptr');
    _export_descriptor_name_ptr = _lib.lookupFunction<
        NativeWasmerExportDescriptorNamePtrFn,
        WasmerExportDescriptorNamePtrFn>('wasmer_export_descriptor_name_ptr');
    _import_descriptors = _lib.lookupFunction<NativeWasmerImportDescriptorsFn,
        WasmerImportDescriptorsFn>('wasmer_import_descriptors');
    _import_descriptors_destroy = _lib.lookupFunction<
        NativeWasmerImportDescriptorsDestroyFn,
        WasmerImportDescriptorsDestroyFn>('wasmer_import_descriptors_destroy');
    _import_descriptors_len = _lib.lookupFunction<
        NativeWasmerImportDescriptorsLenFn,
        WasmerImportDescriptorsLenFn>('wasmer_import_descriptors_len');
    _import_descriptors_get = _lib.lookupFunction<
        NativeWasmerImportDescriptorsGetFn,
        WasmerImportDescriptorsGetFn>('wasmer_import_descriptors_get');
    _import_descriptor_kind = _lib.lookupFunction<
        NativeWasmerImportDescriptorKindFn,
        WasmerImportDescriptorKindFn>('wasmer_import_descriptor_kind');
    _import_descriptor_module_name_ptr = _lib.lookupFunction<
            NativeWasmerImportDescriptorModuleNamePtrFn,
            WasmerImportDescriptorModuleNamePtrFn>(
        'wasmer_import_descriptor_module_name_ptr');
    _import_descriptor_name_ptr = _lib.lookupFunction<
        NativeWasmerImportDescriptorNamePtrFn,
        WasmerImportDescriptorNamePtrFn>('wasmer_import_descriptor_name_ptr');
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

  String _callStringWrapperFunction(Function fn, dynamic arg) {
    var strPtr = allocate<WasmerByteArray>();
    fn(arg, strPtr);
    var str = strPtr.ref.string;
    free(strPtr);
    return str;
  }

  List<WasmExportDescriptor> exportDescriptors(Pointer<WasmerModule> module) {
    var exportsPtrPtr = allocate<Pointer<WasmerExportDescriptors>>();
    _export_descriptors(module, exportsPtrPtr);
    Pointer<WasmerExportDescriptors> exportsPtr = exportsPtrPtr.value;
    free(exportsPtrPtr);
    var n = _export_descriptors_len(exportsPtr);
    var exps = <WasmExportDescriptor>[];
    for (var i = 0; i < n; ++i) {
      var exp = _export_descriptors_get(exportsPtr, i);
      exps.add(WasmExportDescriptor(_export_descriptor_kind(exp),
          _callStringWrapperFunction(_export_descriptor_name_ptr, exp)));
    }
    _export_descriptors_destroy(exportsPtr);
    return exps;
  }

  List<WasmImportDescriptor> importDescriptors(Pointer<WasmerModule> module) {
    var importsPtrPtr = allocate<Pointer<WasmerImportDescriptors>>();
    _import_descriptors(module, importsPtrPtr);
    Pointer<WasmerImportDescriptors> importsPtr = importsPtrPtr.value;
    free(importsPtrPtr);

    var n = _import_descriptors_len(importsPtr);
    var imps = <WasmImportDescriptor>[];
    for (var i = 0; i < n; ++i) {
      var imp = _import_descriptors_get(importsPtr, i);
      imps.add(WasmImportDescriptor(
          _import_descriptor_kind(imp),
          _callStringWrapperFunction(_import_descriptor_module_name_ptr, imp),
          _callStringWrapperFunction(_import_descriptor_name_ptr, imp)));
    }
    _import_descriptors_destroy(importsPtr);
    return imps;
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

  String exportName(Pointer<WasmerExport> export) {
    return _callStringWrapperFunction(_export_name_ptr, export);
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
    result = _export_func_returns(func, returnsPtr, 1);
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
