// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// Manages memory on the native heap.
abstract class Allocator {
  /// This interface is meant to be implemented, not extended or mixed in.
  Allocator._() {
    throw UnsupportedError("Cannot be instantiated");
  }

  /// Allocates [byteCount] bytes of memory on the native heap.
  ///
  /// If [alignment] is provided, the allocated memory will be at least aligned
  /// to [alignment] bytes.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment});

  /// Releases memory allocated on the native heap.
  ///
  /// Throws an [ArgumentError] if the memory pointed to by [pointer] cannot be
  /// freed.
  void free(Pointer pointer);
}

/// Extension on [Allocator] to provide allocation with [NativeType].
extension AllocatorAlloc on Allocator {
  /// Allocates `sizeOf<T>() * count` bytes of memory using
  /// `allocator.allocate`.
  ///
  /// This extension method must be invoked with a compile-time constant [T].
  external Pointer<T> call<T extends NativeType>([int count = 1]);
}
