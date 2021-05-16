// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

/**
 * Foreign Function Interface for interoperability with the C programming language.
 *
 * For further details, please see: https://dart.dev/server/c-interop
 *
 * {@category VM}
 */
library dart.ffi;

import 'dart:isolate';
import 'dart:typed_data';

part "native_type.dart";
part "allocation.dart";
part "annotations.dart";
part "dynamic_library.dart";
part "struct.dart";
part "union.dart";

/// Number of bytes used by native type T.
///
/// Includes padding and alignment of structs.
///
/// This function must be invoked with a compile-time constant [T].
external int sizeOf<T extends NativeType>();

/// Represents a pointer into the native C memory corresponding to "NULL", e.g.
/// a pointer with address 0.
final Pointer<Never> nullptr = Pointer.fromAddress(0);

/// Represents a pointer into the native C memory. Cannot be extended.
@pragma("vm:entry-point")
class Pointer<T extends NativeType> extends NativeType {
  /// Construction from raw integer.
  external factory Pointer.fromAddress(int ptr);

  /// Convert Dart function to a C function pointer, automatically marshalling
  /// the arguments and return value
  ///
  /// If an exception is thrown while calling `f()`, the native function will
  /// return `exceptionalReturn`, which must be assignable to return type of `f`.
  ///
  /// The returned function address can only be invoked on the mutator (main)
  /// thread of the current isolate. It will abort the process if invoked on any
  /// other thread.
  ///
  /// The pointer returned will remain alive for the duration of the current
  /// isolate's lifetime. After the isolate it was created in is terminated,
  /// invoking it from native code will cause undefined behavior.
  ///
  /// Does not accept dynamic invocations -- where the type of the receiver is
  /// [dynamic].
  external static Pointer<NativeFunction<T>> fromFunction<T extends Function>(
      @DartRepresentationOf("T") Function f,
      [Object? exceptionalReturn]);

  /// Access to the raw pointer value.
  /// On 32-bit systems, the upper 32-bits of the result are 0.
  external int get address;

  /// Pointer arithmetic (takes element size into account).
  ///
  /// This method must be invoked with a compile-time constant [T].
  ///
  /// Does not accept dynamic invocations -- where the type of the receiver is
  /// [dynamic].
  external Pointer<T> elementAt(int index);

  /// Cast Pointer<T> to a Pointer<V>.
  external Pointer<U> cast<U extends NativeType>();

  /// Equality for Pointers only depends on their address.
  bool operator ==(Object other) {
    if (other is! Pointer) return false;
    Pointer otherPointer = other;
    return address == otherPointer.address;
  }

  /// The hash code for a Pointer only depends on its address.
  int get hashCode {
    return address.hashCode;
  }
}

/// A fixed-sized array of [T]s.
class Array<T extends NativeType> extends NativeType {
  /// Const constructor to specify [Array] dimensions in [Struct]s.
  ///
  /// ```dart
  /// class MyStruct extends Struct {
  ///   @Array(8)
  ///   external Array<Uint8> inlineArray;
  ///
  ///   @Array(2, 2, 2)
  ///   external Array<Array<Array<Uint8>>> threeDimensionalInlineArray;
  /// }
  /// ```
  ///
  /// Do not invoke in normal code.
  const factory Array(int dimension1,
      [int dimension2,
      int dimension3,
      int dimension4,
      int dimension5]) = _ArraySize<T>;

  /// Const constructor to specify [Array] dimensions in [Struct]s.
  ///
  /// ```dart
  /// class MyStruct extends Struct {
  ///   @Array.multi([2, 2, 2])
  ///   external Array<Array<Array<Uint8>>> threeDimensionalInlineArray;
  ///
  ///   @Array.multi([2, 2, 2, 2, 2, 2, 2, 2])
  ///   external Array<Array<Array<Array<Array<Array<Array<Array<Uint8>>>>>>>> eightDimensionalInlineArray;
  /// }
  /// ```
  ///
  /// Do not invoke in normal code.
  const factory Array.multi(List<int> dimensions) = _ArraySize<T>.multi;
}

class _ArraySize<T extends NativeType> implements Array<T> {
  final int? dimension1;
  final int? dimension2;
  final int? dimension3;
  final int? dimension4;
  final int? dimension5;

  final List<int>? dimensions;

  const _ArraySize(this.dimension1,
      [this.dimension2, this.dimension3, this.dimension4, this.dimension5])
      : dimensions = null;

  const _ArraySize.multi(this.dimensions)
      : dimension1 = null,
        dimension2 = null,
        dimension3 = null,
        dimension4 = null,
        dimension5 = null;
}

/// Extension on [Pointer] specialized for the type argument [NativeFunction].
extension NativeFunctionPointer<NF extends Function>
    on Pointer<NativeFunction<NF>> {
  /// Convert to Dart function, automatically marshalling the arguments
  /// and return value.
  external DF asFunction<@DartRepresentationOf("NF") DF extends Function>();
}

//
// The following code is generated, do not edit by hand.
//
// Code generated by `runtime/tools/ffi/sdk_lib_ffi_generator.dart`.
//

/// Extension on [Pointer] specialized for the type argument [Int8].
extension Int8Pointer on Pointer<Int8> {
  /// The 8-bit two's complement integer at [address].
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toSigned(8)`) before
  /// being stored, and the 8-bit value is sign-extended when it is loaded.
  external int get value;

  external void set value(int value);

  /// The 8-bit two's complement integer at `address + index`.
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toSigned(8)`) before
  /// being stored, and the 8-bit value is sign-extended when it is loaded.
  external int operator [](int index);

  /// The 8-bit two's complement integer at `address + index`.
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toSigned(8)`) before
  /// being stored, and the 8-bit value is sign-extended when it is loaded.
  external void operator []=(int index, int value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  external Int8List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [Int16].
extension Int16Pointer on Pointer<Int16> {
  /// The 16-bit two's complement integer at [address].
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toSigned(16)`) before
  /// being stored, and the 16-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 16-bit two's complement integer at `address + 2 * index`.
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toSigned(16)`) before
  /// being stored, and the 16-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external int operator [](int index);

  /// The 16-bit two's complement integer at `address + 2 * index`.
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toSigned(16)`) before
  /// being stored, and the 16-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external void operator []=(int index, int value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + 2 * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// The [address] must be 2-byte aligned.
  external Int16List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [Int32].
extension Int32Pointer on Pointer<Int32> {
  /// The 32-bit two's complement integer at [address].
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toSigned(32)`) before
  /// being stored, and the 32-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 32-bit two's complement integer at `address + 4 * index`.
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toSigned(32)`) before
  /// being stored, and the 32-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external int operator [](int index);

  /// The 32-bit two's complement integer at `address + 4 * index`.
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toSigned(32)`) before
  /// being stored, and the 32-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external void operator []=(int index, int value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + 4 * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// The [address] must be 4-byte aligned.
  external Int32List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [Int64].
extension Int64Pointer on Pointer<Int64> {
  /// The 64-bit two's complement integer at [address].
  ///
  /// The [address] must be 8-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 64-bit two's complement integer at `address + 8 * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external int operator [](int index);

  /// The 64-bit two's complement integer at `address + 8 * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external void operator []=(int index, int value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + 8 * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// The [address] must be 8-byte aligned.
  external Int64List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [Uint8].
extension Uint8Pointer on Pointer<Uint8> {
  /// The 8-bit unsigned integer at [address].
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toUnsigned(8)`) before
  /// being stored, and the 8-bit value is zero-extended when it is loaded.
  external int get value;

  external void set value(int value);

  /// The 8-bit unsigned integer at `address + index`.
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toUnsigned(8)`) before
  /// being stored, and the 8-bit value is zero-extended when it is loaded.
  external int operator [](int index);

  /// The 8-bit unsigned integer at `address + index`.
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toUnsigned(8)`) before
  /// being stored, and the 8-bit value is zero-extended when it is loaded.
  external void operator []=(int index, int value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  external Uint8List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [Uint16].
extension Uint16Pointer on Pointer<Uint16> {
  /// The 16-bit unsigned integer at [address].
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toUnsigned(16)`) before
  /// being stored, and the 16-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 16-bit unsigned integer at `address + 2 * index`.
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toUnsigned(16)`) before
  /// being stored, and the 16-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external int operator [](int index);

  /// The 16-bit unsigned integer at `address + 2 * index`.
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toUnsigned(16)`) before
  /// being stored, and the 16-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external void operator []=(int index, int value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + 2 * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// The [address] must be 2-byte aligned.
  external Uint16List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [Uint32].
extension Uint32Pointer on Pointer<Uint32> {
  /// The 32-bit unsigned integer at [address].
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toUnsigned(32)`) before
  /// being stored, and the 32-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 32-bit unsigned integer at `address + 4 * index`.
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toUnsigned(32)`) before
  /// being stored, and the 32-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external int operator [](int index);

  /// The 32-bit unsigned integer at `address + 4 * index`.
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toUnsigned(32)`) before
  /// being stored, and the 32-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external void operator []=(int index, int value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + 4 * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// The [address] must be 4-byte aligned.
  external Uint32List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [Uint64].
extension Uint64Pointer on Pointer<Uint64> {
  /// The 64-bit unsigned integer at [address].
  ///
  /// The [address] must be 8-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 64-bit unsigned integer at `address + 8 * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external int operator [](int index);

  /// The 64-bit unsigned integer at `address + 8 * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external void operator []=(int index, int value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + 8 * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// The [address] must be 8-byte aligned.
  external Uint64List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [IntPtr].
extension IntPtrPointer on Pointer<IntPtr> {
  /// The 32 or 64-bit two's complement integer at [address].
  ///
  /// On 32-bit platforms this is a 32-bit integer, and on 64-bit platforms
  /// this is a 64-bit integer.
  ///
  /// On 32-bit platforms a Dart integer is truncated to 32 bits (as if by
  /// `.toSigned(32)`) before being stored, and the 32-bit value is
  /// sign-extended when it is loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 32 or 64-bit two's complement integer at `address + (4 or 8) * index`.
  ///
  /// On 32-bit platforms this is a 32-bit integer, and on 64-bit platforms
  /// this is a 64-bit integer.
  ///
  /// On 32-bit platforms a Dart integer is truncated to 32 bits (as if by
  /// `.toSigned(32)`) before being stored, and the 32-bit value is
  /// sign-extended when it is loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external int operator [](int index);

  /// The 32 or 64-bit two's complement integer at `address + (4 or 8) * index`.
  ///
  /// On 32-bit platforms this is a 32-bit integer, and on 64-bit platforms
  /// this is a 64-bit integer.
  ///
  /// On 32-bit platforms a Dart integer is truncated to 32 bits (as if by
  /// `.toSigned(32)`) before being stored, and the 32-bit value is
  /// sign-extended when it is loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external void operator []=(int index, int value);
}

/// Extension on [Pointer] specialized for the type argument [Float].
extension FloatPointer on Pointer<Float> {
  /// The float at [address].
  ///
  /// A Dart double loses precision before being stored, and the float value is
  /// converted to a double when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external double get value;

  external void set value(double value);

  /// The float at `address + 4 * index`.
  ///
  /// A Dart double loses precision before being stored, and the float value is
  /// converted to a double when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external double operator [](int index);

  /// The float at `address + 4 * index`.
  ///
  /// A Dart double loses precision before being stored, and the float value is
  /// converted to a double when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external void operator []=(int index, double value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + 4 * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// The [address] must be 4-byte aligned.
  external Float32List asTypedList(int length);
}

/// Extension on [Pointer] specialized for the type argument [Double].
extension DoublePointer on Pointer<Double> {
  /// The double at [address].
  ///
  /// The [address] must be 8-byte aligned.
  external double get value;

  external void set value(double value);

  /// The double at `address + 8 * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external double operator [](int index);

  /// The double at `address + 8 * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external void operator []=(int index, double value);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + 8 * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// The [address] must be 8-byte aligned.
  external Float64List asTypedList(int length);
}

/// Bounds checking indexing methods on [Array]s of [Int8].
extension Int8Array on Array<Int8> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Int16].
extension Int16Array on Array<Int16> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Int32].
extension Int32Array on Array<Int32> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Int64].
extension Int64Array on Array<Int64> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Uint8].
extension Uint8Array on Array<Uint8> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Uint16].
extension Uint16Array on Array<Uint16> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Uint32].
extension Uint32Array on Array<Uint32> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Uint64].
extension Uint64Array on Array<Uint64> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [IntPtr].
extension IntPtrArray on Array<IntPtr> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Float].
extension FloatArray on Array<Float> {
  external double operator [](int index);

  external void operator []=(int index, double value);
}

/// Bounds checking indexing methods on [Array]s of [Double].
extension DoubleArray on Array<Double> {
  external double operator [](int index);

  external void operator []=(int index, double value);
}

//
// End of generated code.
//

/// Extension on [Pointer] specialized for the type argument [Pointer].
extension PointerPointer<T extends NativeType> on Pointer<Pointer<T>> {
  /// The pointer at [address].
  ///
  /// A [Pointer] is unboxed before being stored (as if by `.address`), and the
  /// pointer is boxed (as if by `Pointer.fromAddress`) when loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external Pointer<T> get value;

  external void set value(Pointer<T> value);

  /// Load a Dart value from this location offset by [index].
  ///
  /// A [Pointer] is unboxed before being stored (as if by `.address`), and the
  /// pointer is boxed (as if by `Pointer.fromAddress`) when loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external Pointer<T> operator [](int index);

  /// Store a Dart value into this location offset by [index].
  ///
  /// A [Pointer] is unboxed before being stored (as if by `.address`), and the
  /// pointer is boxed (as if by `Pointer.fromAddress`) when loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external void operator []=(int index, Pointer<T> value);
}

/// Extension on [Pointer] specialized for the type argument [Struct].
extension StructPointer<T extends Struct> on Pointer<T> {
  /// Creates a reference to access the fields of this struct backed by native
  /// memory at [address].
  ///
  /// The [address] must be aligned according to the struct alignment rules of
  /// the platform.
  ///
  /// This extension method must be invoked with a compile-time constant [T].
  external T get ref;

  /// Creates a reference to access the fields of this struct backed by native
  /// memory at `address + sizeOf<T>() * index`.
  ///
  /// The [address] must be aligned according to the struct alignment rules of
  /// the platform.
  ///
  /// This extension method must be invoked with a compile-time constant [T].
  external T operator [](int index);
}

/// Extension on [Pointer] specialized for the type argument [Union].
extension UnionPointer<T extends Union> on Pointer<T> {
  /// Creates a reference to access the fields of this union backed by native
  /// memory at [address].
  ///
  /// The [address] must be aligned according to the union alignment rules of
  /// the platform.
  ///
  /// This extension method must be invoked with a compile-time constant [T].
  external T get ref;

  /// Creates a reference to access the fields of this union backed by native
  /// memory at `address + sizeOf<T>() * index`.
  ///
  /// The [address] must be aligned according to the union alignment rules of
  /// the platform.
  ///
  /// This extension method must be invoked with a compile-time constant [T].
  external T operator [](int index);
}

/// Bounds checking indexing methods on [Array]s of [Pointer].
extension PointerArray<T extends NativeType> on Array<Pointer<T>> {
  external Pointer<T> operator [](int index);

  external void operator []=(int index, Pointer<T> value);
}

/// Bounds checking indexing methods on [Array]s of [Struct].
extension StructArray<T extends Struct> on Array<T> {
  /// This extension method must be invoked with a compile-time constant [T].
  external T operator [](int index);
}

/// Bounds checking indexing methods on [Array]s of [Union].
extension UnionArray<T extends Union> on Array<T> {
  /// This extension method must be invoked with a compile-time constant [T].
  external T operator [](int index);
}

/// Bounds checking indexing methods on [Array]s of [Array].
extension ArrayArray<T extends NativeType> on Array<Array<T>> {
  external Array<T> operator [](int index);

  external void operator []=(int index, Array<T> value);
}

/// Extension to retrieve the native `Dart_Port` from a [SendPort].
extension NativePort on SendPort {
  /// The native port of this [SendPort].
  ///
  /// The returned native port can for example be used by C code to post
  /// messages to the connected [ReceivePort] via `Dart_PostCObject()` - see
  /// `dart_native_api.h`.
  external int get nativePort;
}

/// Opaque, not exposing it's members.
class Dart_CObject extends Opaque {}

typedef Dart_NativeMessageHandler = Void Function(Int64, Pointer<Dart_CObject>);

/// Utilities for accessing the Dart VM API from Dart code or
/// from C code via `dart_api_dl.h`.
abstract class NativeApi {
  /// On breaking changes the major version is increased.
  ///
  /// The versioning covers the API surface in `dart_api_dl.h`.
  external static int get majorVersion;

  /// On backwards compatible changes the minor version is increased.
  ///
  /// The versioning covers the API surface in `dart_api_dl.h`.
  external static int get minorVersion;

  /// A function pointer to
  /// `bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message)`
  /// in `dart_native_api.h`.
  external static Pointer<
          NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
      get postCObject;

  /// A function pointer to
  /// ```c
  /// Dart_Port Dart_NewNativePort(const char* name,
  ///                              Dart_NativeMessageHandler handler,
  ///                              bool handle_concurrently)
  /// ```
  /// in `dart_native_api.h`.
  external static Pointer<
      NativeFunction<
          Int64 Function(
              Pointer<Uint8>,
              Pointer<NativeFunction<Dart_NativeMessageHandler>>,
              Int8)>> get newNativePort;

  /// A function pointer to
  /// `bool Dart_CloseNativePort(Dart_Port native_port_id)`
  /// in `dart_native_api.h`.
  external static Pointer<NativeFunction<Int8 Function(Int64)>>
      get closeNativePort;

  /// Pass this to `Dart_InitializeApiDL` in your native code to enable using the
  /// symbols in `dart_api_dl.h`.
  external static Pointer<Void> get initializeApiDLData;
}
