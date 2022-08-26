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
class WasmAnyRef extends _WasmBase {
  /// Upcast Dart object to `anyref`.
  external factory WasmAnyRef.fromObject(Object o);

  /// Whether this reference is a Dart object.
  external bool get isObject;

  /// Downcast `anyref` to a Dart object.
  ///
  /// Will throw if the reference is not a Dart object.
  external Object toObject();
}

/// The Wasm `funcref` type.
@pragma("wasm:entry-point")
class WasmFuncRef extends WasmAnyRef {
  /// Upcast typed function reference to `funcref`
  external factory WasmFuncRef.fromWasmFunction(WasmFunction<Function> fun);

  /// Downcast `anyref` to `funcref`.
  ///
  /// Will throw if the reference is not a `funcref`.
  external factory WasmFuncRef.fromRef(WasmAnyRef ref);
}

/// The Wasm `eqref` type.
@pragma("wasm:entry-point")
class WasmEqRef extends WasmAnyRef {
  /// Upcast Dart object to `eqref`.
  external factory WasmEqRef.fromObject(Object o);
}

/// The Wasm `dataref` type.
@pragma("wasm:entry-point")
class WasmDataRef extends WasmEqRef {
  /// Upcast Dart object to `dataref`.
  external factory WasmDataRef.fromObject(Object o);
}

abstract class _WasmArray extends WasmDataRef {
  /// Dummy factory to silence error about missing superclass constructor.
  external factory _WasmArray._dummy();

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
class WasmI32 extends _WasmInt {
  external factory WasmI32.fromInt(int value);
  external int toIntSigned();
  external int toIntUnsigned();
}

/// The Wasm `i64` type.
@pragma("wasm:entry-point")
class WasmI64 extends _WasmInt {
  external factory WasmI64.fromInt(int value);
  external int toInt();
}

/// The Wasm `f32` type.
@pragma("wasm:entry-point")
class WasmF32 extends _WasmFloat {
  external factory WasmF32.fromDouble(double value);
  external double toDouble();
}

/// The Wasm `f64` type.
@pragma("wasm:entry-point")
class WasmF64 extends _WasmFloat {
  external factory WasmF64.fromDouble(double value);
  external double toDouble();
}

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

/// Wasm typed function reference.
@pragma("wasm:entry-point")
class WasmFunction<F extends Function> extends WasmFuncRef {
  /// Create a typed function reference referring to the given function.
  ///
  /// The argument must directly name a static function with no optional
  /// parameters and no type parameters.
  external factory WasmFunction.fromFunction(F f);

  /// Downcast `anyref` to a typed function reference.
  ///
  /// Will throw if the reference is not a function with the expected signature.
  external factory WasmFunction.fromRef(WasmAnyRef ref);

  /// Call the function referred to by this typed function reference.
  @pragma("wasm:entry-point")
  external F get call;
}

extension IntToWasmInt on int {
  WasmI32 toWasmI32() => WasmI32.fromInt(this);
  WasmI64 toWasmI64() => WasmI64.fromInt(this);
}

extension DoubleToWasmFloat on double {
  WasmF32 toWasmF32() => WasmF32.fromDouble(this);
  WasmF64 toWasmF64() => WasmF64.fromDouble(this);
}
