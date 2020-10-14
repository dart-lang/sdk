// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the following command
// "generate_ffi_boilerplate.py".

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
  late WasmerByteVecDeleteFn _byte_vec_delete;
  late WasmerByteVecNewFn _byte_vec_new;
  late WasmerByteVecNewEmptyFn _byte_vec_new_empty;
  late WasmerByteVecNewUninitializedFn _byte_vec_new_uninitialized;
  late WasmerEngineDeleteFn _engine_delete;
  late WasmerEngineNewFn _engine_new;
  late WasmerExporttypeNameFn _exporttype_name;
  late WasmerExporttypeTypeFn _exporttype_type;
  late WasmerExporttypeVecDeleteFn _exporttype_vec_delete;
  late WasmerExporttypeVecNewFn _exporttype_vec_new;
  late WasmerExporttypeVecNewEmptyFn _exporttype_vec_new_empty;
  late WasmerExporttypeVecNewUninitializedFn _exporttype_vec_new_uninitialized;
  late WasmerExternAsFuncFn _extern_as_func;
  late WasmerExternAsMemoryFn _extern_as_memory;
  late WasmerExternDeleteFn _extern_delete;
  late WasmerExternKindFn _extern_kind;
  late WasmerExternVecDeleteFn _extern_vec_delete;
  late WasmerExternVecNewFn _extern_vec_new;
  late WasmerExternVecNewEmptyFn _extern_vec_new_empty;
  late WasmerExternVecNewUninitializedFn _extern_vec_new_uninitialized;
  late WasmerExterntypeAsFunctypeFn _externtype_as_functype;
  late WasmerExterntypeDeleteFn _externtype_delete;
  late WasmerExterntypeKindFn _externtype_kind;
  late WasmerFuncCallFn _func_call;
  late WasmerFuncDeleteFn _func_delete;
  late WasmerFunctypeDeleteFn _functype_delete;
  late WasmerFunctypeParamsFn _functype_params;
  late WasmerFunctypeResultsFn _functype_results;
  late WasmerImporttypeModuleFn _importtype_module;
  late WasmerImporttypeNameFn _importtype_name;
  late WasmerImporttypeTypeFn _importtype_type;
  late WasmerImporttypeVecDeleteFn _importtype_vec_delete;
  late WasmerImporttypeVecNewFn _importtype_vec_new;
  late WasmerImporttypeVecNewEmptyFn _importtype_vec_new_empty;
  late WasmerImporttypeVecNewUninitializedFn _importtype_vec_new_uninitialized;
  late WasmerInstanceDeleteFn _instance_delete;
  late WasmerInstanceExportsFn _instance_exports;
  late WasmerInstanceNewFn _instance_new;
  late WasmerMemoryDataFn _memory_data;
  late WasmerMemoryDataSizeFn _memory_data_size;
  late WasmerMemoryDeleteFn _memory_delete;
  late WasmerMemoryGrowFn _memory_grow;
  late WasmerMemoryNewFn _memory_new;
  late WasmerMemorySizeFn _memory_size;
  late WasmerMemorytypeDeleteFn _memorytype_delete;
  late WasmerMemorytypeNewFn _memorytype_new;
  late WasmerModuleDeleteFn _module_delete;
  late WasmerModuleExportsFn _module_exports;
  late WasmerModuleImportsFn _module_imports;
  late WasmerModuleNewFn _module_new;
  late WasmerStoreDeleteFn _store_delete;
  late WasmerStoreNewFn _store_new;
  late WasmerTrapDeleteFn _trap_delete;
  late WasmerValtypeDeleteFn _valtype_delete;
  late WasmerValtypeKindFn _valtype_kind;
  late WasmerValtypeVecDeleteFn _valtype_vec_delete;
  late WasmerValtypeVecNewFn _valtype_vec_new;
  late WasmerValtypeVecNewEmptyFn _valtype_vec_new_empty;
  late WasmerValtypeVecNewUninitializedFn _valtype_vec_new_uninitialized;

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
    _byte_vec_delete =
        _lib.lookupFunction<NativeWasmerByteVecDeleteFn, WasmerByteVecDeleteFn>(
            'wasm_byte_vec_delete');
    _byte_vec_new =
        _lib.lookupFunction<NativeWasmerByteVecNewFn, WasmerByteVecNewFn>(
            'wasm_byte_vec_new');
    _byte_vec_new_empty = _lib.lookupFunction<NativeWasmerByteVecNewEmptyFn,
        WasmerByteVecNewEmptyFn>('wasm_byte_vec_new_empty');
    _byte_vec_new_uninitialized = _lib.lookupFunction<
        NativeWasmerByteVecNewUninitializedFn,
        WasmerByteVecNewUninitializedFn>('wasm_byte_vec_new_uninitialized');
    _engine_delete =
        _lib.lookupFunction<NativeWasmerEngineDeleteFn, WasmerEngineDeleteFn>(
            'wasm_engine_delete');
    _engine_new =
        _lib.lookupFunction<NativeWasmerEngineNewFn, WasmerEngineNewFn>(
            'wasm_engine_new');
    _exporttype_name = _lib.lookupFunction<NativeWasmerExporttypeNameFn,
        WasmerExporttypeNameFn>('wasm_exporttype_name');
    _exporttype_type = _lib.lookupFunction<NativeWasmerExporttypeTypeFn,
        WasmerExporttypeTypeFn>('wasm_exporttype_type');
    _exporttype_vec_delete = _lib.lookupFunction<
        NativeWasmerExporttypeVecDeleteFn,
        WasmerExporttypeVecDeleteFn>('wasm_exporttype_vec_delete');
    _exporttype_vec_new = _lib.lookupFunction<NativeWasmerExporttypeVecNewFn,
        WasmerExporttypeVecNewFn>('wasm_exporttype_vec_new');
    _exporttype_vec_new_empty = _lib.lookupFunction<
        NativeWasmerExporttypeVecNewEmptyFn,
        WasmerExporttypeVecNewEmptyFn>('wasm_exporttype_vec_new_empty');
    _exporttype_vec_new_uninitialized = _lib.lookupFunction<
            NativeWasmerExporttypeVecNewUninitializedFn,
            WasmerExporttypeVecNewUninitializedFn>(
        'wasm_exporttype_vec_new_uninitialized');
    _extern_as_func =
        _lib.lookupFunction<NativeWasmerExternAsFuncFn, WasmerExternAsFuncFn>(
            'wasm_extern_as_func');
    _extern_as_memory = _lib.lookupFunction<NativeWasmerExternAsMemoryFn,
        WasmerExternAsMemoryFn>('wasm_extern_as_memory');
    _extern_delete =
        _lib.lookupFunction<NativeWasmerExternDeleteFn, WasmerExternDeleteFn>(
            'wasm_extern_delete');
    _extern_kind =
        _lib.lookupFunction<NativeWasmerExternKindFn, WasmerExternKindFn>(
            'wasm_extern_kind');
    _extern_vec_delete = _lib.lookupFunction<NativeWasmerExternVecDeleteFn,
        WasmerExternVecDeleteFn>('wasm_extern_vec_delete');
    _extern_vec_new =
        _lib.lookupFunction<NativeWasmerExternVecNewFn, WasmerExternVecNewFn>(
            'wasm_extern_vec_new');
    _extern_vec_new_empty = _lib.lookupFunction<NativeWasmerExternVecNewEmptyFn,
        WasmerExternVecNewEmptyFn>('wasm_extern_vec_new_empty');
    _extern_vec_new_uninitialized = _lib.lookupFunction<
        NativeWasmerExternVecNewUninitializedFn,
        WasmerExternVecNewUninitializedFn>('wasm_extern_vec_new_uninitialized');
    _externtype_as_functype = _lib.lookupFunction<
        NativeWasmerExterntypeAsFunctypeFn,
        WasmerExterntypeAsFunctypeFn>('wasm_externtype_as_functype');
    _externtype_delete = _lib.lookupFunction<NativeWasmerExterntypeDeleteFn,
        WasmerExterntypeDeleteFn>('wasm_externtype_delete');
    _externtype_kind = _lib.lookupFunction<NativeWasmerExterntypeKindFn,
        WasmerExterntypeKindFn>('wasm_externtype_kind');
    _func_call = _lib.lookupFunction<NativeWasmerFuncCallFn, WasmerFuncCallFn>(
        'wasm_func_call');
    _func_delete =
        _lib.lookupFunction<NativeWasmerFuncDeleteFn, WasmerFuncDeleteFn>(
            'wasm_func_delete');
    _functype_delete = _lib.lookupFunction<NativeWasmerFunctypeDeleteFn,
        WasmerFunctypeDeleteFn>('wasm_functype_delete');
    _functype_params = _lib.lookupFunction<NativeWasmerFunctypeParamsFn,
        WasmerFunctypeParamsFn>('wasm_functype_params');
    _functype_results = _lib.lookupFunction<NativeWasmerFunctypeResultsFn,
        WasmerFunctypeResultsFn>('wasm_functype_results');
    _importtype_module = _lib.lookupFunction<NativeWasmerImporttypeModuleFn,
        WasmerImporttypeModuleFn>('wasm_importtype_module');
    _importtype_name = _lib.lookupFunction<NativeWasmerImporttypeNameFn,
        WasmerImporttypeNameFn>('wasm_importtype_name');
    _importtype_type = _lib.lookupFunction<NativeWasmerImporttypeTypeFn,
        WasmerImporttypeTypeFn>('wasm_importtype_type');
    _importtype_vec_delete = _lib.lookupFunction<
        NativeWasmerImporttypeVecDeleteFn,
        WasmerImporttypeVecDeleteFn>('wasm_importtype_vec_delete');
    _importtype_vec_new = _lib.lookupFunction<NativeWasmerImporttypeVecNewFn,
        WasmerImporttypeVecNewFn>('wasm_importtype_vec_new');
    _importtype_vec_new_empty = _lib.lookupFunction<
        NativeWasmerImporttypeVecNewEmptyFn,
        WasmerImporttypeVecNewEmptyFn>('wasm_importtype_vec_new_empty');
    _importtype_vec_new_uninitialized = _lib.lookupFunction<
            NativeWasmerImporttypeVecNewUninitializedFn,
            WasmerImporttypeVecNewUninitializedFn>(
        'wasm_importtype_vec_new_uninitialized');
    _instance_delete = _lib.lookupFunction<NativeWasmerInstanceDeleteFn,
        WasmerInstanceDeleteFn>('wasm_instance_delete');
    _instance_exports = _lib.lookupFunction<NativeWasmerInstanceExportsFn,
        WasmerInstanceExportsFn>('wasm_instance_exports');
    _instance_new =
        _lib.lookupFunction<NativeWasmerInstanceNewFn, WasmerInstanceNewFn>(
            'wasm_instance_new');
    _memory_data =
        _lib.lookupFunction<NativeWasmerMemoryDataFn, WasmerMemoryDataFn>(
            'wasm_memory_data');
    _memory_data_size = _lib.lookupFunction<NativeWasmerMemoryDataSizeFn,
        WasmerMemoryDataSizeFn>('wasm_memory_data_size');
    _memory_delete =
        _lib.lookupFunction<NativeWasmerMemoryDeleteFn, WasmerMemoryDeleteFn>(
            'wasm_memory_delete');
    _memory_grow =
        _lib.lookupFunction<NativeWasmerMemoryGrowFn, WasmerMemoryGrowFn>(
            'wasm_memory_grow');
    _memory_new =
        _lib.lookupFunction<NativeWasmerMemoryNewFn, WasmerMemoryNewFn>(
            'wasm_memory_new');
    _memory_size =
        _lib.lookupFunction<NativeWasmerMemorySizeFn, WasmerMemorySizeFn>(
            'wasm_memory_size');
    _memorytype_delete = _lib.lookupFunction<NativeWasmerMemorytypeDeleteFn,
        WasmerMemorytypeDeleteFn>('wasm_memorytype_delete');
    _memorytype_new =
        _lib.lookupFunction<NativeWasmerMemorytypeNewFn, WasmerMemorytypeNewFn>(
            'wasm_memorytype_new');
    _module_delete =
        _lib.lookupFunction<NativeWasmerModuleDeleteFn, WasmerModuleDeleteFn>(
            'wasm_module_delete');
    _module_exports =
        _lib.lookupFunction<NativeWasmerModuleExportsFn, WasmerModuleExportsFn>(
            'wasm_module_exports');
    _module_imports =
        _lib.lookupFunction<NativeWasmerModuleImportsFn, WasmerModuleImportsFn>(
            'wasm_module_imports');
    _module_new =
        _lib.lookupFunction<NativeWasmerModuleNewFn, WasmerModuleNewFn>(
            'wasm_module_new');
    _store_delete =
        _lib.lookupFunction<NativeWasmerStoreDeleteFn, WasmerStoreDeleteFn>(
            'wasm_store_delete');
    _store_new = _lib.lookupFunction<NativeWasmerStoreNewFn, WasmerStoreNewFn>(
        'wasm_store_new');
    _trap_delete =
        _lib.lookupFunction<NativeWasmerTrapDeleteFn, WasmerTrapDeleteFn>(
            'wasm_trap_delete');
    _valtype_delete =
        _lib.lookupFunction<NativeWasmerValtypeDeleteFn, WasmerValtypeDeleteFn>(
            'wasm_valtype_delete');
    _valtype_kind =
        _lib.lookupFunction<NativeWasmerValtypeKindFn, WasmerValtypeKindFn>(
            'wasm_valtype_kind');
    _valtype_vec_delete = _lib.lookupFunction<NativeWasmerValtypeVecDeleteFn,
        WasmerValtypeVecDeleteFn>('wasm_valtype_vec_delete');
    _valtype_vec_new =
        _lib.lookupFunction<NativeWasmerValtypeVecNewFn, WasmerValtypeVecNewFn>(
            'wasm_valtype_vec_new');
    _valtype_vec_new_empty = _lib.lookupFunction<
        NativeWasmerValtypeVecNewEmptyFn,
        WasmerValtypeVecNewEmptyFn>('wasm_valtype_vec_new_empty');
    _valtype_vec_new_uninitialized = _lib.lookupFunction<
            NativeWasmerValtypeVecNewUninitializedFn,
            WasmerValtypeVecNewUninitializedFn>(
        'wasm_valtype_vec_new_uninitialized');

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
