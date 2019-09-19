// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.5

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
/// by native memory. The may allocated via [Pointer.allocate] or loaded from a
/// [Pointer], but not by a generative constructor.
abstract class Struct<S extends NativeType> extends NativeType {
  /// Returns the address backing the reference.
  final Pointer<S> addressOf;

  Struct() : addressOf = null;
  Struct.fromPointer(this.addressOf);
}
