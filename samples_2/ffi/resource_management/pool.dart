// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Explicit pool used for managing resources.

// @dart = 2.9

import "dart:async";
import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// An [Allocator] which frees all allocations at the same time.
///
/// The pool allows you to allocate heap memory, but ignores calls to [free].
/// Instead you call [releaseAll] to release all the allocations at the same
/// time.
///
/// Also allows other resources to be associated with the pool, through the
/// [using] method, to have a release function called for them when the pool is
/// released.
///
/// An [Allocator] can be provided to do the actual allocation and freeing.
/// Defaults to using [calloc].
class Pool implements Allocator {
  /// The [Allocator] used for allocation and freeing.
  final Allocator _wrappedAllocator;

  /// Native memory under management by this [Pool].
  final List<Pointer<NativeType>> _managedMemoryPointers = [];

  /// Callbacks for releasing native resources under management by this [Pool].
  final List<Function()> _managedResourceReleaseCallbacks = [];

  bool _inUse = true;

  /// Creates a pool of allocations.
  ///
  /// The [allocator] is used to do the actual allocation and freeing of
  /// memory. It defaults to using [calloc].
  Pool([Allocator allocator = calloc]) : _wrappedAllocator = allocator;

  /// Allocates memory and includes it in the pool.
  ///
  /// Uses the allocator provided to the [Pool] constructor to do the
  /// allocation.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int alignment}) {
    _ensureInUse();
    final p = _wrappedAllocator.allocate<T>(byteCount, alignment: alignment);
    _managedMemoryPointers.add(p);
    return p;
  }

  /// Registers [resource] in this pool.
  ///
  /// Executes [releaseCallback] on [releaseAll].
  T using<T>(T resource, Function(T) releaseCallback) {
    _ensureInUse();
    releaseCallback = Zone.current.bindUnaryCallback(releaseCallback);
    _managedResourceReleaseCallbacks.add(() => releaseCallback(resource));
    return resource;
  }

  /// Registers [releaseResourceCallback] to be executed on [releaseAll].
  void onReleaseAll(Function() releaseResourceCallback) {
    _managedResourceReleaseCallbacks.add(releaseResourceCallback);
  }

  /// Releases all resources that this [Pool] manages.
  ///
  /// If [reuse] is `true`, the pool can be used again after resources
  /// have been released. If not, the default, then the [allocate]
  /// and [using] methods must not be called after a call to `releaseAll`.
  void releaseAll({bool reuse = false}) {
    if (!reuse) {
      _inUse = false;
    }
    while (_managedResourceReleaseCallbacks.isNotEmpty) {
      _managedResourceReleaseCallbacks.removeLast()();
    }
    for (final p in _managedMemoryPointers) {
      _wrappedAllocator.free(p);
    }
    _managedMemoryPointers.clear();
  }

  /// Does nothing, invoke [releaseAll] instead.
  @override
  void free(Pointer<NativeType> pointer) {}

  void _ensureInUse() {
    if (!_inUse) {
      throw StateError(
          "Pool no longer in use, `releaseAll(reuse: false)` was called.");
    }
  }
}

/// Runs [computation] with a new [Pool], and releases all allocations at the end.
///
/// If [R] is a [Future], all allocations are released when the future completes.
///
/// If the isolate is shut down, through `Isolate.kill()`, resources are _not_
/// cleaned up.
R using<R>(R Function(Pool) computation,
    [Allocator wrappedAllocator = calloc]) {
  final pool = Pool(wrappedAllocator);
  bool isAsync = false;
  try {
    final result = computation(pool);
    if (result is Future) {
      isAsync = true;
      return (result.whenComplete(pool.releaseAll) as R);
    }
    return result;
  } finally {
    if (!isAsync) {
      pool.releaseAll();
    }
  }
}

/// Creates a zoned [Pool] to manage native resources.
///
/// The pool is availabe through [zonePool].
///
/// If the isolate is shut down, through `Isolate.kill()`, resources are _not_ cleaned up.
R withZonePool<R>(R Function() computation,
    [Allocator wrappedAllocator = calloc]) {
  final pool = Pool(wrappedAllocator);
  var poolHolder = [pool];
  bool isAsync = false;
  try {
    return runZoned(() {
      final result = computation();
      if (result is Future) {
        isAsync = true;
        result.whenComplete(pool.releaseAll);
      }
      return result;
    }, zoneValues: {#_pool: poolHolder});
  } finally {
    if (!isAsync) {
      pool.releaseAll();
      poolHolder.remove(pool);
    }
  }
}

/// A zone-specific [Pool].
///
/// Asynchronous computations can share a [Pool]. Use [withZonePool] to create
/// a new zone with a fresh [Pool], and that pool will then be released
/// automatically when the function passed to [withZonePool] completes.
/// All code inside that zone can use `zonePool` to access the pool.
///
/// The current pool must not be accessed by code which is not running inside
/// a zone created by [withZonePool].
Pool get zonePool {
  final List<Pool> poolHolder = Zone.current[#_pool];
  if (poolHolder == null) {
    throw StateError("Not inside a zone created by `usePool`");
  }
  if (!poolHolder.isEmpty) {
    return poolHolder.single;
  }
  throw StateError("Pool as already been cleared with releaseAll.");
}
