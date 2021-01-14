// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Explicit pool used for managing resources.

// @dart = 2.9

import "dart:async";
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../calloc.dart';

/// Keeps track of all allocated memory and frees all allocated memory on
/// [releaseAll].
///
/// Wraps an [Allocator] to do the actual allocation and freeing.
class Pool implements Allocator {
  /// The [Allocator] used for allocation and freeing.
  final Allocator _wrappedAllocator;

  Pool(this._wrappedAllocator);

  /// Native memory under management by this [Pool].
  final List<Pointer<NativeType>> _managedMemoryPointers = [];

  /// Callbacks for releasing native resources under management by this [Pool].
  final List<Function()> _managedResourceReleaseCallbacks = [];

  /// Allocates memory on the native heap by using the allocator supplied to
  /// the constructor.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  @override
  Pointer<T> allocate<T extends NativeType>(int numBytes, {int alignment}) {
    final p = _wrappedAllocator.allocate<T>(numBytes, alignment: alignment);
    _managedMemoryPointers.add(p);
    return p;
  }

  /// Registers [resource] in this pool.
  ///
  /// Executes [releaseCallback] on [releaseAll].
  T using<T>(T resource, Function(T) releaseCallback) {
    _managedResourceReleaseCallbacks.add(() => releaseCallback(resource));
    return resource;
  }

  /// Registers [releaseResourceCallback] to be executed on [releaseAll].
  void onReleaseAll(Function() releaseResourceCallback) {
    _managedResourceReleaseCallbacks.add(releaseResourceCallback);
  }

  /// Releases all resources that this [Pool] manages.
  void releaseAll() {
    for (final c in _managedResourceReleaseCallbacks) {
      c();
    }
    _managedResourceReleaseCallbacks.clear();
    for (final p in _managedMemoryPointers) {
      _wrappedAllocator.free(p);
    }
    _managedMemoryPointers.clear();
  }

  @override
  void free(Pointer<NativeType> pointer) => throw UnsupportedError(
      "Individually freeing Pool allocated memory is not allowed");
}

/// Creates a [Pool] to manage native resources.
///
/// If the isolate is shut down, through `Isolate.kill()`, resources are _not_ cleaned up.
R using<R>(R Function(Pool) f, [Allocator wrappedAllocator = calloc]) {
  final p = Pool(wrappedAllocator);
  try {
    return f(p);
  } finally {
    p.releaseAll();
  }
}

/// Creates a zoned [Pool] to manage native resources.
///
/// Pool is availabe through [currentPool].
///
/// Please note that all throws are caught and packaged in [RethrownError].
///
/// If the isolate is shut down, through `Isolate.kill()`, resources are _not_ cleaned up.
R usePool<R>(R Function() f, [Allocator wrappedAllocator = calloc]) {
  final p = Pool(wrappedAllocator);
  try {
    return runZoned(() => f(),
        zoneValues: {#_pool: p},
        onError: (error, st) => throw RethrownError(error, st));
  } finally {
    p.releaseAll();
  }
}

/// The [Pool] in the current zone.
Pool get currentPool => Zone.current[#_pool];

class RethrownError {
  dynamic original;
  StackTrace originalStackTrace;
  RethrownError(this.original, this.originalStackTrace);
  toString() => """RethrownError(${original})
${originalStackTrace}""";
}
