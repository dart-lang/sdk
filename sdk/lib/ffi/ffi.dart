// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

/**
 * Foreign Function Interface for interoperability with the C programming language.
 *
 * **NOTE**: Dart:FFI is in technical preview. The overall feature is incomplete,
 * may contain issues, and breaking API changes are still expected.
 *
 * For further details, please see: https://dart.dev/server/c-interop
 *
 * {@category VM}
 */
library dart.ffi;

import 'dart:typed_data' show TypedData;

part "native_type.dart";
part "annotations.dart";
part "dynamic_library.dart";
part "struct.dart";

/// Number of bytes used by native type T.
///
/// Includes padding and alignment of structs.
external int sizeOf<T extends NativeType>();

/// Represents a pointer into the native C memory.
final Pointer<Void> nullptr = Pointer.fromAddress(0);

/// Represents a pointer into the native C memory. Cannot be extended.
@pragma("vm:entry-point")
class Pointer<T extends NativeType> extends NativeType {
  /// Allocate [count] elements of type [T] on the native heap via malloc() and
  /// return a pointer to the newly allocated memory.
  ///
  /// Note that the memory is uninitialized.
  external factory Pointer.allocate({int count: 1});

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
      [Object exceptionalReturn]);

  /// Store a Dart value into this location.
  ///
  /// The [value] is automatically marshalled into its native representation.
  /// Note that ints which do not fit in [T] are truncated and sign extended,
  /// and doubles stored into Pointer<[Float]> lose precision.
  external void store(@DartRepresentationOf("T") Object value);

  /// Load a Dart value from this location.
  ///
  /// The value is automatically unmarshalled from its native representation.
  /// Loading a [Struct] reference returns a reference backed by native memory
  /// (the same pointer as it's loaded from).
  external R load<@DartRepresentationOf("T") R>();

  /// Access to the raw pointer value.
  /// On 32-bit systems, the upper 32-bits of the result are 0.
  external int get address;

  /// Pointer arithmetic (takes element size into account).
  external Pointer<T> elementAt(int index);

  /// Pointer arithmetic (byte offset).
  // TODO(dacoharkes): remove this?
  // https://github.com/dart-lang/sdk/issues/35883
  external Pointer<T> offsetBy(int offsetInBytes);

  /// Cast Pointer<T> to a Pointer<V>.
  external Pointer<U> cast<U extends NativeType>();

  /// Convert to Dart function, automatically marshalling the arguments
  /// and return value.
  ///
  /// Can only be called on [Pointer]<[NativeFunction]>. Does not accept dynamic
  /// invocations -- where the type of the receiver is [dynamic].
  external R asFunction<@DartRepresentationOf("T") R extends Function>();

  /// Free memory on the C heap pointed to by this pointer with free().
  ///
  /// Note that this zeros out the address.
  external void free();

  /// Creates an *external* typed data array backed by this pointer.
  ///
  /// The typed data array returned is only valid for as long as the backing
  /// [Pointer]. Accessing any element of the type data array after this
  /// [Pointer] has been [Pointer.free()]d will cause undefined behavior.
  ///
  /// Since [Pointer]s do not know their length, the size of the typed data is
  /// controlled by `count`, in units of the size of the native type for this
  /// [Pointer] (similarly to [Pointer.allocate]).
  ///
  /// The kind of TypedData produced depends on the native type:
  ///
  ///   Pointer<Int8> -> Int8List
  ///   Pointer<Uint8> -> Uint8List
  ///   etc. up to Int64/Uint64
  ///   Pointer<IntPtr> -> Int32List/Int64List depending on platform word size
  ///   Pointer<Float> -> Float32List
  ///   Pointer<Double> -> Float64List
  ///
  /// Creation of a [Uint8ClampedList] is not supported. Creation of a typed
  /// data from a [Pointer] to any other native type is not supported.
  ///
  /// The pointer must be aligned to a multiple of the native type's size.
  //
  // TODO(37773): Use extension methods to articulate more precise return types.
  // We should still keep this member though as a generic way to access a
  // Pointer of unknown type.
  external TypedData asExternalTypedData({int count: 1});

  /// Equality for Pointers only depends on their address.
  bool operator ==(other) {
    if (other == null) return false;
    return address == other.address;
  }

  /// The hash code for a Pointer only depends on its address.
  int get hashCode {
    return address.hashCode;
  }
}
