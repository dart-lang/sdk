// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// This class is extended to define structs.
///
/// Fields in a struct, annotated with a subtype of [NativeType], are
/// automatically transformed into wrappers to access the fields of the struct
/// in native memory.
///
/// All fields in a struct must either have a type which extends [NativeType] or
/// else have an annotation indicating the corresponding native type (e.g.
/// "@Int32()" for "int").
///
/// Instances of a subclass of [Struct] have reference semantics and are backed
/// by native memory. The may allocated via allocation or loaded from a
/// [Pointer], but not by a generative constructor.
abstract class Struct extends NativeType {
  final Pointer<Struct> _addressOf;

  /// Construct a reference to the [nullptr].
  ///
  /// Use [StructPointer]'s `.ref` to gain references to native memory backed
  /// structs.
  Struct() : _addressOf = nullptr;

  Struct._fromPointer(this._addressOf);
}

/// Extension on [Struct] specialized for it's subtypes.
extension StructAddressOf<T extends Struct> on T {
  /// Returns the address backing the reference.
  Pointer<T> get addressOf => _addressOf as Pointer<T>;
}
