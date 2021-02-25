// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the following command
// "generate_ffi_boilerplate.py".

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

// wasm_valkind_enum
const int WasmerValKindI32 = 0;
const int WasmerValKindI64 = 1;
const int WasmerValKindF32 = 2;
const int WasmerValKindF64 = 3;
// The void tag is not part of the C API. It's used to represent the return type
// of a void function.
const int WasmerValKindVoid = -1;

// wasm_externkind_enum
const int WasmerExternKindFunction = 0;
const int WasmerExternKindGlobal = 1;
const int WasmerExternKindTable = 2;
const int WasmerExternKindMemory = 3;

String wasmerExternKindName(int kind) {
  switch (kind) {
    case WasmerExternKindFunction:
      return "function";
    case WasmerExternKindGlobal:
      return "global";
    case WasmerExternKindTable:
      return "table";
    case WasmerExternKindMemory:
      return "memory";
    default:
      return "unknown";
  }
}

String wasmerValKindName(int kind) {
  switch (kind) {
    case WasmerValKindI32:
      return "int32";
    case WasmerValKindI64:
      return "int64";
    case WasmerValKindF32:
      return "float32";
    case WasmerValKindF64:
      return "float64";
    case WasmerValKindVoid:
      return "void";
    default:
      return "unknown";
  }
}

// wasm_val_t
class WasmerVal extends Struct {
  // wasm_valkind_t
  @Uint8()
  external int kind;

  // This is a union of int32_t, int64_t, float, and double. The kind determines
  // which type it is. It's declared as an int64_t because that's large enough
  // to hold all the types. We use ByteData to get the other types.
  @Int64()
  external int value;

  int get _off32 => Endian.host == Endian.little ? 0 : 4;
  int get i64 => value;
  ByteData get _getterBytes => ByteData(8)..setInt64(0, value, Endian.host);
  int get i32 => _getterBytes.getInt32(_off32, Endian.host);
  double get f32 => _getterBytes.getFloat32(_off32, Endian.host);
  double get f64 => _getterBytes.getFloat64(0, Endian.host);

  set i64(int val) => value = val;
  set _val(ByteData bytes) => value = bytes.getInt64(0, Endian.host);
  set i32(int val) => _val = ByteData(8)..setInt32(_off32, val, Endian.host);
  set f32(num val) =>
      _val = ByteData(8)..setFloat32(_off32, val as double, Endian.host);
  set f64(num val) =>
      _val = ByteData(8)..setFloat64(0, val as double, Endian.host);

  bool get isI32 => kind == WasmerValKindI32;
  bool get isI64 => kind == WasmerValKindI64;
  bool get isF32 => kind == WasmerValKindF32;
  bool get isF64 => kind == WasmerValKindF64;

  dynamic get toDynamic {
    switch (kind) {
      case WasmerValKindI32:
        return i32;
      case WasmerValKindI64:
        return i64;
      case WasmerValKindF32:
        return f32;
      case WasmerValKindF64:
        return f64;
    }
  }
}

// wasmer_limits_t
class WasmerLimits extends Struct {
  @Uint32()
  external int min;

  @Uint32()
  external int max;
}

// Default maximum, which indicates no upper limit.
const int wasm_limits_max_default = 0xffffffff;

// wasm_engine_t
class WasmerEngine extends Struct {}

// wasm_exporttype_t
class WasmerExporttype extends Struct {}

// wasm_extern_t
class WasmerExtern extends Struct {}

// wasm_externtype_t
class WasmerExterntype extends Struct {}

// wasm_func_t
class WasmerFunc extends Struct {}

// wasm_functype_t
class WasmerFunctype extends Struct {}

// wasm_importtype_t
class WasmerImporttype extends Struct {}

// wasm_instance_t
class WasmerInstance extends Struct {}

// wasm_memory_t
class WasmerMemory extends Struct {}

// wasm_memorytype_t
class WasmerMemorytype extends Struct {}

// wasm_module_t
class WasmerModule extends Struct {}

// wasm_store_t
class WasmerStore extends Struct {}

// wasm_trap_t
class WasmerTrap extends Struct {}

// wasm_valtype_t
class WasmerValtype extends Struct {}

// wasi_config_t
class WasmerWasiConfig extends Struct {}

// wasi_env_t
class WasmerWasiEnv extends Struct {}

// wasm_byte_vec_t
class WasmerByteVec extends Struct {
  @Uint64()
  external int length;

  external Pointer<Uint8> data;

  Uint8List get list => data.asTypedList(length);
  String toString() => utf8.decode(list);
}

// wasm_exporttype_vec_t
class WasmerExporttypeVec extends Struct {
  @Uint64()
  external int length;

  external Pointer<Pointer<WasmerExporttype>> data;
}

// wasm_extern_vec_t
class WasmerExternVec extends Struct {
  @Uint64()
  external int length;

  external Pointer<Pointer<WasmerExtern>> data;
}

// wasm_importtype_vec_t
class WasmerImporttypeVec extends Struct {
  @Uint64()
  external int length;

  external Pointer<Pointer<WasmerImporttype>> data;
}

// wasm_val_vec_t
class WasmerValVec extends Struct {
  @Uint64()
  external int length;

  external Pointer<WasmerVal> data;
}

// wasm_valtype_vec_t
class WasmerValtypeVec extends Struct {
  @Uint64()
  external int length;

  external Pointer<Pointer<WasmerValtype>> data;
}

// Dart_InitializeApiDL
typedef NativeWasmerDartInitializeApiDLFn = Int64 Function(Pointer<Void>);
typedef WasmerDartInitializeApiDLFn = int Function(Pointer<Void>);

// set_finalizer_for_engine
typedef NativeWasmerSetFinalizerForEngineFn = Void Function(
    Handle, Pointer<WasmerEngine>);
typedef WasmerSetFinalizerForEngineFn = void Function(
    Object, Pointer<WasmerEngine>);

// set_finalizer_for_func
typedef NativeWasmerSetFinalizerForFuncFn = Void Function(
    Handle, Pointer<WasmerFunc>);
typedef WasmerSetFinalizerForFuncFn = void Function(
    Object, Pointer<WasmerFunc>);

// set_finalizer_for_instance
typedef NativeWasmerSetFinalizerForInstanceFn = Void Function(
    Handle, Pointer<WasmerInstance>);
typedef WasmerSetFinalizerForInstanceFn = void Function(
    Object, Pointer<WasmerInstance>);

// set_finalizer_for_memory
typedef NativeWasmerSetFinalizerForMemoryFn = Void Function(
    Handle, Pointer<WasmerMemory>);
typedef WasmerSetFinalizerForMemoryFn = void Function(
    Object, Pointer<WasmerMemory>);

// set_finalizer_for_memorytype
typedef NativeWasmerSetFinalizerForMemorytypeFn = Void Function(
    Handle, Pointer<WasmerMemorytype>);
typedef WasmerSetFinalizerForMemorytypeFn = void Function(
    Object, Pointer<WasmerMemorytype>);

// set_finalizer_for_module
typedef NativeWasmerSetFinalizerForModuleFn = Void Function(
    Handle, Pointer<WasmerModule>);
typedef WasmerSetFinalizerForModuleFn = void Function(
    Object, Pointer<WasmerModule>);

// set_finalizer_for_store
typedef NativeWasmerSetFinalizerForStoreFn = Void Function(
    Handle, Pointer<WasmerStore>);
typedef WasmerSetFinalizerForStoreFn = void Function(
    Object, Pointer<WasmerStore>);

// set_finalizer_for_trap
typedef NativeWasmerSetFinalizerForTrapFn = Void Function(
    Handle, Pointer<WasmerTrap>);
typedef WasmerSetFinalizerForTrapFn = void Function(
    Object, Pointer<WasmerTrap>);

// wasi_config_inherit_stderr
typedef NativeWasmerWasiConfigInheritStderrFn = Void Function(
    Pointer<WasmerWasiConfig>);
typedef WasmerWasiConfigInheritStderrFn = void Function(
    Pointer<WasmerWasiConfig>);

// wasi_config_inherit_stdout
typedef NativeWasmerWasiConfigInheritStdoutFn = Void Function(
    Pointer<WasmerWasiConfig>);
typedef WasmerWasiConfigInheritStdoutFn = void Function(
    Pointer<WasmerWasiConfig>);

// wasi_config_new
typedef NativeWasmerWasiConfigNewFn = Pointer<WasmerWasiConfig> Function(
    Pointer<Uint8>);
typedef WasmerWasiConfigNewFn = Pointer<WasmerWasiConfig> Function(
    Pointer<Uint8>);

// wasi_env_delete
typedef NativeWasmerWasiEnvDeleteFn = Void Function(Pointer<WasmerWasiEnv>);
typedef WasmerWasiEnvDeleteFn = void Function(Pointer<WasmerWasiEnv>);

// wasi_env_new
typedef NativeWasmerWasiEnvNewFn = Pointer<WasmerWasiEnv> Function(
    Pointer<WasmerWasiConfig>);
typedef WasmerWasiEnvNewFn = Pointer<WasmerWasiEnv> Function(
    Pointer<WasmerWasiConfig>);

// wasi_env_read_stderr
typedef NativeWasmerWasiEnvReadStderrFn = Int64 Function(
    Pointer<WasmerWasiEnv>, Pointer<Uint8>, Uint64);
typedef WasmerWasiEnvReadStderrFn = int Function(
    Pointer<WasmerWasiEnv>, Pointer<Uint8>, int);

// wasi_env_read_stdout
typedef NativeWasmerWasiEnvReadStdoutFn = Int64 Function(
    Pointer<WasmerWasiEnv>, Pointer<Uint8>, Uint64);
typedef WasmerWasiEnvReadStdoutFn = int Function(
    Pointer<WasmerWasiEnv>, Pointer<Uint8>, int);

// wasi_env_set_memory
typedef NativeWasmerWasiEnvSetMemoryFn = Void Function(
    Pointer<WasmerWasiEnv>, Pointer<WasmerMemory>);
typedef WasmerWasiEnvSetMemoryFn = void Function(
    Pointer<WasmerWasiEnv>, Pointer<WasmerMemory>);

// wasi_get_imports
typedef NativeWasmerWasiGetImportsFn = Uint8 Function(Pointer<WasmerStore>,
    Pointer<WasmerModule>, Pointer<WasmerWasiEnv>, Pointer<WasmerExternVec>);
typedef WasmerWasiGetImportsFn = int Function(Pointer<WasmerStore>,
    Pointer<WasmerModule>, Pointer<WasmerWasiEnv>, Pointer<WasmerExternVec>);

// wasm_byte_vec_delete
typedef NativeWasmerByteVecDeleteFn = Void Function(Pointer<WasmerByteVec>);
typedef WasmerByteVecDeleteFn = void Function(Pointer<WasmerByteVec>);

// wasm_byte_vec_new
typedef NativeWasmerByteVecNewFn = Void Function(
    Pointer<WasmerByteVec>, Uint64, Pointer<Uint8>);
typedef WasmerByteVecNewFn = void Function(
    Pointer<WasmerByteVec>, int, Pointer<Uint8>);

// wasm_byte_vec_new_empty
typedef NativeWasmerByteVecNewEmptyFn = Void Function(Pointer<WasmerByteVec>);
typedef WasmerByteVecNewEmptyFn = void Function(Pointer<WasmerByteVec>);

// wasm_byte_vec_new_uninitialized
typedef NativeWasmerByteVecNewUninitializedFn = Void Function(
    Pointer<WasmerByteVec>, Uint64);
typedef WasmerByteVecNewUninitializedFn = void Function(
    Pointer<WasmerByteVec>, int);

// wasm_engine_delete
typedef NativeWasmerEngineDeleteFn = Void Function(Pointer<WasmerEngine>);
typedef WasmerEngineDeleteFn = void Function(Pointer<WasmerEngine>);

// wasm_engine_new
typedef NativeWasmerEngineNewFn = Pointer<WasmerEngine> Function();
typedef WasmerEngineNewFn = Pointer<WasmerEngine> Function();

// wasm_exporttype_name
typedef NativeWasmerExporttypeNameFn = Pointer<WasmerByteVec> Function(
    Pointer<WasmerExporttype>);
typedef WasmerExporttypeNameFn = Pointer<WasmerByteVec> Function(
    Pointer<WasmerExporttype>);

// wasm_exporttype_type
typedef NativeWasmerExporttypeTypeFn = Pointer<WasmerExterntype> Function(
    Pointer<WasmerExporttype>);
typedef WasmerExporttypeTypeFn = Pointer<WasmerExterntype> Function(
    Pointer<WasmerExporttype>);

// wasm_exporttype_vec_delete
typedef NativeWasmerExporttypeVecDeleteFn = Void Function(
    Pointer<WasmerExporttypeVec>);
typedef WasmerExporttypeVecDeleteFn = void Function(
    Pointer<WasmerExporttypeVec>);

// wasm_exporttype_vec_new
typedef NativeWasmerExporttypeVecNewFn = Void Function(
    Pointer<WasmerExporttypeVec>, Uint64, Pointer<Pointer<WasmerExporttype>>);
typedef WasmerExporttypeVecNewFn = void Function(
    Pointer<WasmerExporttypeVec>, int, Pointer<Pointer<WasmerExporttype>>);

// wasm_exporttype_vec_new_empty
typedef NativeWasmerExporttypeVecNewEmptyFn = Void Function(
    Pointer<WasmerExporttypeVec>);
typedef WasmerExporttypeVecNewEmptyFn = void Function(
    Pointer<WasmerExporttypeVec>);

// wasm_exporttype_vec_new_uninitialized
typedef NativeWasmerExporttypeVecNewUninitializedFn = Void Function(
    Pointer<WasmerExporttypeVec>, Uint64);
typedef WasmerExporttypeVecNewUninitializedFn = void Function(
    Pointer<WasmerExporttypeVec>, int);

// wasm_extern_as_func
typedef NativeWasmerExternAsFuncFn = Pointer<WasmerFunc> Function(
    Pointer<WasmerExtern>);
typedef WasmerExternAsFuncFn = Pointer<WasmerFunc> Function(
    Pointer<WasmerExtern>);

// wasm_extern_as_memory
typedef NativeWasmerExternAsMemoryFn = Pointer<WasmerMemory> Function(
    Pointer<WasmerExtern>);
typedef WasmerExternAsMemoryFn = Pointer<WasmerMemory> Function(
    Pointer<WasmerExtern>);

// wasm_extern_delete
typedef NativeWasmerExternDeleteFn = Void Function(Pointer<WasmerExtern>);
typedef WasmerExternDeleteFn = void Function(Pointer<WasmerExtern>);

// wasm_extern_kind
typedef NativeWasmerExternKindFn = Uint8 Function(Pointer<WasmerExtern>);
typedef WasmerExternKindFn = int Function(Pointer<WasmerExtern>);

// wasm_extern_vec_delete
typedef NativeWasmerExternVecDeleteFn = Void Function(Pointer<WasmerExternVec>);
typedef WasmerExternVecDeleteFn = void Function(Pointer<WasmerExternVec>);

// wasm_extern_vec_new
typedef NativeWasmerExternVecNewFn = Void Function(
    Pointer<WasmerExternVec>, Uint64, Pointer<Pointer<WasmerExtern>>);
typedef WasmerExternVecNewFn = void Function(
    Pointer<WasmerExternVec>, int, Pointer<Pointer<WasmerExtern>>);

// wasm_extern_vec_new_empty
typedef NativeWasmerExternVecNewEmptyFn = Void Function(
    Pointer<WasmerExternVec>);
typedef WasmerExternVecNewEmptyFn = void Function(Pointer<WasmerExternVec>);

// wasm_extern_vec_new_uninitialized
typedef NativeWasmerExternVecNewUninitializedFn = Void Function(
    Pointer<WasmerExternVec>, Uint64);
typedef WasmerExternVecNewUninitializedFn = void Function(
    Pointer<WasmerExternVec>, int);

// wasm_externtype_as_functype
typedef NativeWasmerExterntypeAsFunctypeFn = Pointer<WasmerFunctype> Function(
    Pointer<WasmerExterntype>);
typedef WasmerExterntypeAsFunctypeFn = Pointer<WasmerFunctype> Function(
    Pointer<WasmerExterntype>);

// wasm_externtype_delete
typedef NativeWasmerExterntypeDeleteFn = Void Function(
    Pointer<WasmerExterntype>);
typedef WasmerExterntypeDeleteFn = void Function(Pointer<WasmerExterntype>);

// wasm_externtype_kind
typedef NativeWasmerExterntypeKindFn = Uint8 Function(
    Pointer<WasmerExterntype>);
typedef WasmerExterntypeKindFn = int Function(Pointer<WasmerExterntype>);

// wasm_func_as_extern
typedef NativeWasmerFuncAsExternFn = Pointer<WasmerExtern> Function(
    Pointer<WasmerFunc>);
typedef WasmerFuncAsExternFn = Pointer<WasmerExtern> Function(
    Pointer<WasmerFunc>);

// wasm_func_call
typedef NativeWasmerFuncCallFn = Pointer<WasmerTrap> Function(
    Pointer<WasmerFunc>, Pointer<WasmerValVec>, Pointer<WasmerValVec>);
typedef WasmerFuncCallFn = Pointer<WasmerTrap> Function(
    Pointer<WasmerFunc>, Pointer<WasmerValVec>, Pointer<WasmerValVec>);

// wasm_func_delete
typedef NativeWasmerFuncDeleteFn = Void Function(Pointer<WasmerFunc>);
typedef WasmerFuncDeleteFn = void Function(Pointer<WasmerFunc>);

// wasm_func_new_with_env
typedef NativeWasmerFuncNewWithEnvFn = Pointer<WasmerFunc> Function(
    Pointer<WasmerStore>,
    Pointer<WasmerFunctype>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>);
typedef WasmerFuncNewWithEnvFn = Pointer<WasmerFunc> Function(
    Pointer<WasmerStore>,
    Pointer<WasmerFunctype>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>);

// wasm_functype_delete
typedef NativeWasmerFunctypeDeleteFn = Void Function(Pointer<WasmerFunctype>);
typedef WasmerFunctypeDeleteFn = void Function(Pointer<WasmerFunctype>);

// wasm_functype_params
typedef NativeWasmerFunctypeParamsFn = Pointer<WasmerValtypeVec> Function(
    Pointer<WasmerFunctype>);
typedef WasmerFunctypeParamsFn = Pointer<WasmerValtypeVec> Function(
    Pointer<WasmerFunctype>);

// wasm_functype_results
typedef NativeWasmerFunctypeResultsFn = Pointer<WasmerValtypeVec> Function(
    Pointer<WasmerFunctype>);
typedef WasmerFunctypeResultsFn = Pointer<WasmerValtypeVec> Function(
    Pointer<WasmerFunctype>);

// wasm_importtype_module
typedef NativeWasmerImporttypeModuleFn = Pointer<WasmerByteVec> Function(
    Pointer<WasmerImporttype>);
typedef WasmerImporttypeModuleFn = Pointer<WasmerByteVec> Function(
    Pointer<WasmerImporttype>);

// wasm_importtype_name
typedef NativeWasmerImporttypeNameFn = Pointer<WasmerByteVec> Function(
    Pointer<WasmerImporttype>);
typedef WasmerImporttypeNameFn = Pointer<WasmerByteVec> Function(
    Pointer<WasmerImporttype>);

// wasm_importtype_type
typedef NativeWasmerImporttypeTypeFn = Pointer<WasmerExterntype> Function(
    Pointer<WasmerImporttype>);
typedef WasmerImporttypeTypeFn = Pointer<WasmerExterntype> Function(
    Pointer<WasmerImporttype>);

// wasm_importtype_vec_delete
typedef NativeWasmerImporttypeVecDeleteFn = Void Function(
    Pointer<WasmerImporttypeVec>);
typedef WasmerImporttypeVecDeleteFn = void Function(
    Pointer<WasmerImporttypeVec>);

// wasm_importtype_vec_new
typedef NativeWasmerImporttypeVecNewFn = Void Function(
    Pointer<WasmerImporttypeVec>, Uint64, Pointer<Pointer<WasmerImporttype>>);
typedef WasmerImporttypeVecNewFn = void Function(
    Pointer<WasmerImporttypeVec>, int, Pointer<Pointer<WasmerImporttype>>);

// wasm_importtype_vec_new_empty
typedef NativeWasmerImporttypeVecNewEmptyFn = Void Function(
    Pointer<WasmerImporttypeVec>);
typedef WasmerImporttypeVecNewEmptyFn = void Function(
    Pointer<WasmerImporttypeVec>);

// wasm_importtype_vec_new_uninitialized
typedef NativeWasmerImporttypeVecNewUninitializedFn = Void Function(
    Pointer<WasmerImporttypeVec>, Uint64);
typedef WasmerImporttypeVecNewUninitializedFn = void Function(
    Pointer<WasmerImporttypeVec>, int);

// wasm_instance_delete
typedef NativeWasmerInstanceDeleteFn = Void Function(Pointer<WasmerInstance>);
typedef WasmerInstanceDeleteFn = void Function(Pointer<WasmerInstance>);

// wasm_instance_exports
typedef NativeWasmerInstanceExportsFn = Void Function(
    Pointer<WasmerInstance>, Pointer<WasmerExternVec>);
typedef WasmerInstanceExportsFn = void Function(
    Pointer<WasmerInstance>, Pointer<WasmerExternVec>);

// wasm_instance_new
typedef NativeWasmerInstanceNewFn = Pointer<WasmerInstance> Function(
    Pointer<WasmerStore>,
    Pointer<WasmerModule>,
    Pointer<WasmerExternVec>,
    Pointer<Pointer<WasmerTrap>>);
typedef WasmerInstanceNewFn = Pointer<WasmerInstance> Function(
    Pointer<WasmerStore>,
    Pointer<WasmerModule>,
    Pointer<WasmerExternVec>,
    Pointer<Pointer<WasmerTrap>>);

// wasm_memory_as_extern
typedef NativeWasmerMemoryAsExternFn = Pointer<WasmerExtern> Function(
    Pointer<WasmerMemory>);
typedef WasmerMemoryAsExternFn = Pointer<WasmerExtern> Function(
    Pointer<WasmerMemory>);

// wasm_memory_data
typedef NativeWasmerMemoryDataFn = Pointer<Uint8> Function(
    Pointer<WasmerMemory>);
typedef WasmerMemoryDataFn = Pointer<Uint8> Function(Pointer<WasmerMemory>);

// wasm_memory_data_size
typedef NativeWasmerMemoryDataSizeFn = Uint64 Function(Pointer<WasmerMemory>);
typedef WasmerMemoryDataSizeFn = int Function(Pointer<WasmerMemory>);

// wasm_memory_delete
typedef NativeWasmerMemoryDeleteFn = Void Function(Pointer<WasmerMemory>);
typedef WasmerMemoryDeleteFn = void Function(Pointer<WasmerMemory>);

// wasm_memory_grow
typedef NativeWasmerMemoryGrowFn = Uint8 Function(
    Pointer<WasmerMemory>, Uint32);
typedef WasmerMemoryGrowFn = int Function(Pointer<WasmerMemory>, int);

// wasm_memory_new
typedef NativeWasmerMemoryNewFn = Pointer<WasmerMemory> Function(
    Pointer<WasmerStore>, Pointer<WasmerMemorytype>);
typedef WasmerMemoryNewFn = Pointer<WasmerMemory> Function(
    Pointer<WasmerStore>, Pointer<WasmerMemorytype>);

// wasm_memory_size
typedef NativeWasmerMemorySizeFn = Uint32 Function(Pointer<WasmerMemory>);
typedef WasmerMemorySizeFn = int Function(Pointer<WasmerMemory>);

// wasm_memorytype_delete
typedef NativeWasmerMemorytypeDeleteFn = Void Function(
    Pointer<WasmerMemorytype>);
typedef WasmerMemorytypeDeleteFn = void Function(Pointer<WasmerMemorytype>);

// wasm_memorytype_new
typedef NativeWasmerMemorytypeNewFn = Pointer<WasmerMemorytype> Function(
    Pointer<WasmerLimits>);
typedef WasmerMemorytypeNewFn = Pointer<WasmerMemorytype> Function(
    Pointer<WasmerLimits>);

// wasm_module_delete
typedef NativeWasmerModuleDeleteFn = Void Function(Pointer<WasmerModule>);
typedef WasmerModuleDeleteFn = void Function(Pointer<WasmerModule>);

// wasm_module_exports
typedef NativeWasmerModuleExportsFn = Void Function(
    Pointer<WasmerModule>, Pointer<WasmerExporttypeVec>);
typedef WasmerModuleExportsFn = void Function(
    Pointer<WasmerModule>, Pointer<WasmerExporttypeVec>);

// wasm_module_imports
typedef NativeWasmerModuleImportsFn = Void Function(
    Pointer<WasmerModule>, Pointer<WasmerImporttypeVec>);
typedef WasmerModuleImportsFn = void Function(
    Pointer<WasmerModule>, Pointer<WasmerImporttypeVec>);

// wasm_module_new
typedef NativeWasmerModuleNewFn = Pointer<WasmerModule> Function(
    Pointer<WasmerStore>, Pointer<WasmerByteVec>);
typedef WasmerModuleNewFn = Pointer<WasmerModule> Function(
    Pointer<WasmerStore>, Pointer<WasmerByteVec>);

// wasm_store_delete
typedef NativeWasmerStoreDeleteFn = Void Function(Pointer<WasmerStore>);
typedef WasmerStoreDeleteFn = void Function(Pointer<WasmerStore>);

// wasm_store_new
typedef NativeWasmerStoreNewFn = Pointer<WasmerStore> Function(
    Pointer<WasmerEngine>);
typedef WasmerStoreNewFn = Pointer<WasmerStore> Function(Pointer<WasmerEngine>);

// wasm_trap_delete
typedef NativeWasmerTrapDeleteFn = Void Function(Pointer<WasmerTrap>);
typedef WasmerTrapDeleteFn = void Function(Pointer<WasmerTrap>);

// wasm_trap_message
typedef NativeWasmerTrapMessageFn = Void Function(
    Pointer<WasmerTrap>, Pointer<WasmerByteVec>);
typedef WasmerTrapMessageFn = void Function(
    Pointer<WasmerTrap>, Pointer<WasmerByteVec>);

// wasm_trap_new
typedef NativeWasmerTrapNewFn = Pointer<WasmerTrap> Function(
    Pointer<WasmerStore>, Pointer<WasmerByteVec>);
typedef WasmerTrapNewFn = Pointer<WasmerTrap> Function(
    Pointer<WasmerStore>, Pointer<WasmerByteVec>);

// wasm_valtype_delete
typedef NativeWasmerValtypeDeleteFn = Void Function(Pointer<WasmerValtype>);
typedef WasmerValtypeDeleteFn = void Function(Pointer<WasmerValtype>);

// wasm_valtype_kind
typedef NativeWasmerValtypeKindFn = Uint8 Function(Pointer<WasmerValtype>);
typedef WasmerValtypeKindFn = int Function(Pointer<WasmerValtype>);

// wasm_valtype_vec_delete
typedef NativeWasmerValtypeVecDeleteFn = Void Function(
    Pointer<WasmerValtypeVec>);
typedef WasmerValtypeVecDeleteFn = void Function(Pointer<WasmerValtypeVec>);

// wasm_valtype_vec_new
typedef NativeWasmerValtypeVecNewFn = Void Function(
    Pointer<WasmerValtypeVec>, Uint64, Pointer<Pointer<WasmerValtype>>);
typedef WasmerValtypeVecNewFn = void Function(
    Pointer<WasmerValtypeVec>, int, Pointer<Pointer<WasmerValtype>>);

// wasm_valtype_vec_new_empty
typedef NativeWasmerValtypeVecNewEmptyFn = Void Function(
    Pointer<WasmerValtypeVec>);
typedef WasmerValtypeVecNewEmptyFn = void Function(Pointer<WasmerValtypeVec>);

// wasm_valtype_vec_new_uninitialized
typedef NativeWasmerValtypeVecNewUninitializedFn = Void Function(
    Pointer<WasmerValtypeVec>, Uint64);
typedef WasmerValtypeVecNewUninitializedFn = void Function(
    Pointer<WasmerValtypeVec>, int);

// wasmer_last_error_length
typedef NativeWasmerWasmerLastErrorLengthFn = Int64 Function();
typedef WasmerWasmerLastErrorLengthFn = int Function();

// wasmer_last_error_message
typedef NativeWasmerWasmerLastErrorMessageFn = Int64 Function(
    Pointer<Uint8>, Int64);
typedef WasmerWasmerLastErrorMessageFn = int Function(Pointer<Uint8>, int);
