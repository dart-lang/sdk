// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.wasm;

// A collection a special Dart tytpes that are mapped directly to Wasm types
// by the dart2wasm compiler. These types have a number of constraints:
//
// - They can only be used directly as types of local variables, fields, or
//   parameter/return of static functions. No other uses of the types are valid.
// - They are not assignable to or from any ordinary Dart types.
// - The integer and float types can't be nullable.
//
// TODO(askesc): Give an error message if any of these constraints are violated.

@pragma("wasm:entry-point")
abstract class _WasmBase {}

abstract class _WasmInt extends _WasmBase {}

abstract class _WasmFloat extends _WasmBase {}

/// The Wasm `anyref` type.
@pragma("wasm:entry-point")
class WasmAnyRef extends _WasmBase {}

/// The Wasm `eqref` type.
@pragma("wasm:entry-point")
class WasmEqRef extends WasmAnyRef {}

/// The Wasm `dataref` type.
@pragma("wasm:entry-point")
class WasmDataRef extends WasmEqRef {}

abstract class _WasmArray extends WasmDataRef {
  external int get length;
}

/// The Wasm `i8` storage type.
@pragma("wasm:entry-point")
class WasmI8 extends _WasmInt {}

/// The Wasm `i16` storage type.
@pragma("wasm:entry-point")
class WasmI16 extends _WasmInt {}

/// The Wasm `i32` type.
@pragma("wasm:entry-point")
class WasmI32 extends _WasmInt {}

/// The Wasm `i64` type.
@pragma("wasm:entry-point")
class WasmI64 extends _WasmInt {}

/// The Wasm `f32` type.
@pragma("wasm:entry-point")
class WasmF32 extends _WasmFloat {}

/// The Wasm `f64` type.
@pragma("wasm:entry-point")
class WasmF64 extends _WasmFloat {}

/// A Wasm array with integer element type.
@pragma("wasm:entry-point")
class WasmIntArray<T extends _WasmInt> extends _WasmArray {
  external factory WasmIntArray(int length);

  external int readSigned(int index);
  external int readUnsigned(int index);
  external void write(int index, int value);
}

/// A Wasm array with float element type.
@pragma("wasm:entry-point")
class WasmFloatArray<T extends _WasmFloat> extends _WasmArray {
  external factory WasmFloatArray(int length);

  external double read(int index);
  external void write(int index, double value);
}

/// A Wasm array with reference element type, containing Dart objects.
@pragma("wasm:entry-point")
class WasmObjectArray<T extends Object?> extends _WasmArray {
  external factory WasmObjectArray(int length);

  external T read(int index);
  external void write(int index, T value);
}
