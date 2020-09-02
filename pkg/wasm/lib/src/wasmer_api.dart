// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

// wasmer_result_t
const int WasmerResultOk = 1;
const int WasmerResultError = 2;

// wasmer_value_tag
const int WasmerValueTagI32 = 0;
const int WasmerValueTagI64 = 1;
const int WasmerValueTagF32 = 2;
const int WasmerValueTagF64 = 3;
// The void tag is not part of the C API. It's used to represent the return type
// of a void function.
const int WasmerValueTagVoid = -1;

// wasmer_import_export_kind
const int WasmerImpExpKindFunction = 0;
const int WasmerImpExpKindGlobal = 1;
const int WasmerImpExpKindMemory = 2;
const int WasmerImpExpKindTable = 3;

// wasmer_module_t
class WasmerModule extends Struct {}

// wasmer_instance_t
class WasmerInstance extends Struct {}

// wasmer_exports_t
class WasmerExports extends Struct {}

// wasmer_export_t
class WasmerExport extends Struct {}

// wasmer_export_func_t
class WasmerExportFunc extends Struct {}

// wasmer_import_t
class WasmerImport extends Struct {
  Pointer<Uint8> module_name;

  @Uint32()
  int module_name_length;

  Pointer<Uint8> import_name;

  @Uint32()
  int import_name_length;

  // wasmer_import_export_kind
  @Uint32()
  int tag;

  // wasmer_import_export_value, which is a union of wasmer_import_func_t*,
  // wasmer_table_t*, wasmer_memory_t*, and wasmer_global_t*. The tag determines
  // which type it is.
  Pointer<Void> value;
}

// wasmer_byte_array
class WasmerByteArray extends Struct {
  Pointer<Uint8> bytes;

  @Uint32()
  int length;

  Uint8List get list => bytes.asTypedList(length);
}

// wasmer_value_t
class WasmerValue extends Struct {
  // wasmer_value_tag
  @Uint32()
  int tag;

  // wasmer_value, which is a union of int32_t, int64_t, float, and double. The
  // tag determines which type it is. It's declared as an int64_t because that's
  // large enough to hold all the types. We use ByteData to get the other types.
  @Int64()
  int value;

  int get _off32 => Endian.host == Endian.little ? 0 : 4;
  int get i64 => value;
  ByteData get _getterBytes => ByteData(8)..setInt64(0, value, Endian.host);
  int get i32 => _getterBytes.getInt32(_off32, Endian.host);
  double get f32 => _getterBytes.getFloat32(_off32, Endian.host);
  double get f64 => _getterBytes.getFloat64(0, Endian.host);

  set i64(int val) => value = val;
  set _val(ByteData bytes) => value = bytes.getInt64(0, Endian.host);
  set i32(int val) => _val = ByteData(8)..setInt32(_off32, val, Endian.host);
  set f32(num val) => _val = ByteData(8)..setFloat32(_off32, val, Endian.host);
  set f64(num val) => _val = ByteData(8)..setFloat64(0, val, Endian.host);

  bool get isI32 => tag == WasmerValueTagI32;
  bool get isI64 => tag == WasmerValueTagI64;
  bool get isF32 => tag == WasmerValueTagF32;
  bool get isF64 => tag == WasmerValueTagF64;
}

// wasmer_compile
typedef NativeWasmerCompileFn = Uint32 Function(
    Pointer<Pointer<WasmerModule>>, Pointer<Uint8>, Uint32);
typedef WasmerCompileFn = int Function(
    Pointer<Pointer<WasmerModule>>, Pointer<Uint8>, int);

// wasmer_module_instantiate
typedef NativeWasmerInstantiateFn = Uint32 Function(Pointer<WasmerModule>,
    Pointer<Pointer<WasmerInstance>>, Pointer<WasmerImport>, Int32);
typedef WasmerInstantiateFn = int Function(Pointer<WasmerModule>,
    Pointer<Pointer<WasmerInstance>>, Pointer<WasmerImport>, int);

// wasmer_instance_exports
typedef NativeWasmerInstanceExportsFn = Void Function(
    Pointer<WasmerInstance>, Pointer<Pointer<WasmerExports>>);
typedef WasmerInstanceExportsFn = void Function(
    Pointer<WasmerInstance>, Pointer<Pointer<WasmerExports>>);

// wasmer_exports_len
typedef NativeWasmerExportsLenFn = Int32 Function(Pointer<WasmerExports>);
typedef WasmerExportsLenFn = int Function(Pointer<WasmerExports>);

// wasmer_exports_get
typedef NativeWasmerExportsGetFn = Pointer<WasmerExport> Function(
    Pointer<WasmerExports>, Int32);
typedef WasmerExportsGetFn = Pointer<WasmerExport> Function(
    Pointer<WasmerExports>, int);

// wasmer_export_name
typedef NativeWasmerExportNameFn = WasmerByteArray Function(
    Pointer<WasmerExport>);
typedef WasmerExportNameFn = WasmerByteArray Function(Pointer<WasmerExport>);

// wasmer_export_kind
typedef NativeWasmerExportKindFn = Uint32 Function(Pointer<WasmerExport>);
typedef WasmerExportKindFn = int Function(Pointer<WasmerExport>);

// wasmer_export_to_func
typedef NativeWasmerExportToFuncFn = Pointer<WasmerExportFunc> Function(
    Pointer<WasmerExport>);
typedef WasmerExportToFuncFn = Pointer<WasmerExportFunc> Function(
    Pointer<WasmerExport>);

// wasmer_export_func_returns_arity
typedef NativeWasmerExportFuncReturnsArityFn = Uint32 Function(
    Pointer<WasmerExportFunc>, Pointer<Uint32>);
typedef WasmerExportFuncReturnsArityFn = int Function(
    Pointer<WasmerExportFunc>, Pointer<Uint32>);

// wasmer_export_func_returns
typedef NativeWasmerExportFuncReturnsFn = Uint32 Function(
    Pointer<WasmerExportFunc>, Pointer<Uint32>, Uint32);
typedef WasmerExportFuncReturnsFn = int Function(
    Pointer<WasmerExportFunc>, Pointer<Uint32>, int);

// wasmer_export_func_params_arity
typedef NativeWasmerExportFuncParamsArityFn = Uint32 Function(
    Pointer<WasmerExportFunc>, Pointer<Uint32>);
typedef WasmerExportFuncParamsArityFn = int Function(
    Pointer<WasmerExportFunc>, Pointer<Uint32>);

// wasmer_export_func_params
typedef NativeWasmerExportFuncParamsFn = Uint32 Function(
    Pointer<WasmerExportFunc>, Pointer<Uint32>, Uint32);
typedef WasmerExportFuncParamsFn = int Function(
    Pointer<WasmerExportFunc>, Pointer<Uint32>, int);

// wasmer_export_func_call
typedef NativeWasmerExportFuncCallFn = Uint32 Function(
    Pointer<WasmerExportFunc>,
    Pointer<WasmerValue>,
    Uint32,
    Pointer<WasmerValue>,
    Uint32);
typedef WasmerExportFuncCallFn = int Function(Pointer<WasmerExportFunc>,
    Pointer<WasmerValue>, int, Pointer<WasmerValue>, int);
