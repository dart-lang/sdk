// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the following command
// "generate_ffi_boilerplate.py".

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

part 'wasmer_api.g.dart';

// wasm_valkind_enum
const int wasmerValKindI32 = 0;
const int wasmerValKindI64 = 1;
const int wasmerValKindF32 = 2;
const int wasmerValKindF64 = 3;
// The void tag is not part of the C API. It's used to represent the return type
// of a void function.
const int wasmerValKindVoid = -1;

// wasm_externkind_enum
const int wasmerExternKindFunction = 0;
const int wasmerExternKindGlobal = 1;
const int wasmerExternKindTable = 2;
const int wasmerExternKindMemory = 3;

String wasmerExternKindName(int kind) {
  switch (kind) {
    case wasmerExternKindFunction:
      return 'function';
    case wasmerExternKindGlobal:
      return 'global';
    case wasmerExternKindTable:
      return 'table';
    case wasmerExternKindMemory:
      return 'memory';
    default:
      return 'unknown';
  }
}

String wasmerValKindName(int kind) {
  switch (kind) {
    case wasmerValKindI32:
      return 'int32';
    case wasmerValKindI64:
      return 'int64';
    case wasmerValKindF32:
      return 'float32';
    case wasmerValKindF64:
      return 'float64';
    case wasmerValKindVoid:
      return 'void';
    default:
      return 'unknown';
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

  bool get isI32 => kind == wasmerValKindI32;

  bool get isI64 => kind == wasmerValKindI64;

  bool get isF32 => kind == wasmerValKindF32;

  bool get isF64 => kind == wasmerValKindF64;

  dynamic get toDynamic {
    switch (kind) {
      case wasmerValKindI32:
        return i32;
      case wasmerValKindI64:
        return i64;
      case wasmerValKindF32:
        return f32;
      case wasmerValKindF64:
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
const int wasmLimitsMaxDefault = 0xffffffff;
