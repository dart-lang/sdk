// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._wasm;

// A collection a special Dart types that are mapped directly to Wasm types
// by the dart2wasm compiler. These types have a number of constraints:
//
// - They can only be used directly as types of local variables, fields, or
//   parameter/return of static functions. No other uses of the types are valid.
// - They are not assignable to or from any ordinary Dart types.
// - The integer and float types can't be nullable.
// - Their instance methods cannot be called virtually or dynamically.
//
// TODO(askesc): Give an error message if any of these constraints are violated.

@pragma("wasm:entry-point")
abstract class _WasmBase {
  const _WasmBase();
}

abstract class _WasmInt extends _WasmBase {
  const _WasmInt();
}

abstract class _WasmFloat extends _WasmBase {
  const _WasmFloat();
}

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

extension ExternalizeNonNullable on WasmAnyRef {
  WasmExternRef externalize() => _externalizeNonNullable(this);
}

extension ExternalizeNullable on WasmAnyRef? {
  WasmExternRef? externalize() => _externalizeNullable(this);
}

/// The Wasm `externref` type.
@pragma("wasm:entry-point")
class WasmExternRef extends _WasmBase {
  // To avoid conflating the null externref with Dart's null, we provide a
  // special getter for the null externref.
  external static WasmExternRef? get nullRef;
}

extension InternalizeNonNullable on WasmExternRef {
  WasmAnyRef internalize() => _internalizeNonNullable(this);
}

extension InternalizeNullable on WasmExternRef? {
  bool get isNull => _wasmExternRefIsNull(this);
  WasmAnyRef? internalize() => _internalizeNullable(this);
}

external WasmExternRef _externalizeNonNullable(WasmAnyRef ref);
external WasmExternRef? _externalizeNullable(WasmAnyRef? ref);
external WasmAnyRef _internalizeNonNullable(WasmExternRef ref);
external WasmAnyRef? _internalizeNullable(WasmExternRef? ref);
external bool _wasmExternRefIsNull(WasmExternRef? ref);

/// The Wasm `funcref` type.
@pragma("wasm:entry-point")
class WasmFuncRef extends _WasmBase {
  /// Upcast typed function reference to `funcref`
  external factory WasmFuncRef.fromWasmFunction(WasmFunction<Function> fun);
}

/// The Wasm `eqref` type.
@pragma("wasm:entry-point")
class WasmEqRef extends WasmAnyRef {
  /// Upcast Dart object to `eqref`.
  external factory WasmEqRef.fromObject(Object o);
}

/// The Wasm `structref` type.
@pragma("wasm:entry-point")
class WasmStructRef extends WasmEqRef {
  /// Upcast Dart object to `structref`.
  external factory WasmStructRef.fromObject(Object o);
}

/// The Wasm `arrayref` type.
@pragma("wasm:entry-point")
class WasmArrayRef extends WasmEqRef {
  /// Dummy factory to silence error about missing superclass constructor.
  external factory WasmArrayRef._dummy();

  /// Length of array.
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
  /// Dummy value field to contain the value for constant instances.
  final int _value;

  /// Constructor for constant instances.
  const WasmI32(this._value);

  external factory WasmI32.fromInt(int value);
  external factory WasmI32.int8FromInt(int value);
  external factory WasmI32.uint8FromInt(int value);
  external factory WasmI32.int16FromInt(int value);
  external factory WasmI32.uint16FromInt(int value);
  external factory WasmI32.fromBool(bool value);
  external int toIntSigned();
  external int toIntUnsigned();
  external bool toBool();
}

/// The Wasm `i64` type.
@pragma("wasm:entry-point")
class WasmI64 extends _WasmInt {
  /// Dummy value field to contain the value for constant instances.
  final int _value;

  /// Constructor for constant instances.
  const WasmI64(this._value);

  external factory WasmI64.fromInt(int value);
  external int toInt();
}

/// The Wasm `f32` type.
@pragma("wasm:entry-point")
class WasmF32 extends _WasmFloat {
  /// Dummy value field to contain the value for constant instances.
  final double _value;

  /// Constructor for constant instances.
  const WasmF32(this._value);

  external factory WasmF32.fromDouble(double value);
  external double toDouble();
}

/// The Wasm `f64` type.
@pragma("wasm:entry-point")
class WasmF64 extends _WasmFloat {
  /// Dummy value field to contain the value for constant instances.
  final double _value;

  /// Constructor for constant instances.
  const WasmF64(this._value);

  external factory WasmF64.fromDouble(double value);
  external double toDouble();
}

/// A Wasm array with integer element type.
@pragma("wasm:entry-point")
class WasmIntArray<T extends _WasmInt> extends WasmArrayRef {
  external factory WasmIntArray(int length);

  external int readSigned(int index);
  external int readUnsigned(int index);
  external void write(int index, int value);
}

/// A Wasm array with float element type.
@pragma("wasm:entry-point")
class WasmFloatArray<T extends _WasmFloat> extends WasmArrayRef {
  external factory WasmFloatArray(int length);

  external double read(int index);
  external void write(int index, double value);
}

/// A Wasm array with reference element type, containing Dart objects.
@pragma("wasm:entry-point")
class WasmObjectArray<T extends Object?> extends WasmArrayRef {
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

  /// Downcast `funcref` to a typed function reference.
  ///
  /// Will throw if the reference is not a function with the expected signature.
  external factory WasmFunction.fromFuncRef(WasmFuncRef ref);

  /// Call the function referred to by this typed function reference.
  @pragma("wasm:entry-point")
  external F get call;
}

/// A marker type for the return type of functions and the type argument to
/// [WasmFunction] to indicate that the function type should have no outputs.
@pragma("wasm:entry-point")
class WasmVoid extends _WasmBase {}

/// A Wasm table.
@pragma("wasm:entry-point")
class WasmTable<T> extends _WasmBase {
  /// Declare a table with the given size.
  ///
  /// Must be an initializer for a static field. The [size] argument must be
  /// either a constant or a reference to a `static` `final` field with a
  /// constant initializer.
  external WasmTable(int size);

  /// Read from an entry in the table.
  external T operator [](WasmI32 index);

  /// Write to an entry in the table.
  external void operator []=(WasmI32 index, T value);

  /// The size of the table.
  external WasmI32 get size;

  /// Call a function stored in the table using the `call_indirect` Wasm
  /// instruction. The function value returned from this method must be
  /// called directly.
  @pragma("wasm:entry-point")
  external F callIndirect<F extends Function>(WasmI32 index);
}

extension IntToWasmInt on int {
  WasmI32 toWasmI32() => WasmI32.fromInt(this);
  WasmI64 toWasmI64() => WasmI64.fromInt(this);
}

extension DoubleToWasmFloat on double {
  WasmF32 toWasmF32() => WasmF32.fromDouble(this);
  WasmF64 toWasmF64() => WasmF64.fromDouble(this);
}
