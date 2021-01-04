// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Explicit pool used for managing resources.

// @dart = 2.9

import "dart:async";
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as packageFfi;
import 'package:ffi/ffi.dart' show Utf8;

/// Manages native resources.
///
/// Primary implementations are [Pool] and [Unmanaged].
abstract class ResourceManager {
  /// Allocates memory on the native heap.
  ///
  /// The native memory is under management by this [ResourceManager].
  ///
  /// For POSIX-based systems, this uses malloc. On Windows, it uses HeapAlloc
  /// against the default public heap. Allocation of either element size or count
  /// of 0 is undefined.
  ///
  /// Throws an ArgumentError on failure to allocate.
  Pointer<T> allocate<T extends NativeType>({int count: 1});
}

/// Manages native resources.
class Pool implements ResourceManager {
  /// Native memory under management by this [Pool].
  final List<Pointer<NativeType>> _managedMemoryPointers = [];

  /// Callbacks for releasing native resources under management by this [Pool].
  final List<Function()> _managedResourceReleaseCallbacks = [];

  /// Allocates memory on the native heap.
  ///
  /// The native memory is under management by this [Pool].
  ///
  /// For POSIX-based systems, this uses malloc. On Windows, it uses HeapAlloc
  /// against the default public heap. Allocation of either element size or count
  /// of 0 is undefined.
  ///
  /// Throws an ArgumentError on failure to allocate.
  Pointer<T> allocate<T extends NativeType>({int count: 1}) {
    final p = Unmanaged().allocate<T>(count: count);
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
      Unmanaged().free(p);
    }
    _managedMemoryPointers.clear();
  }
}

/// Creates a [Pool] to manage native resources.
///
/// If the isolate is shut down, through `Isolate.kill()`, resources are _not_ cleaned up.
R using<R>(R Function(Pool) f) {
  final p = Pool();
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
R usePool<R>(R Function() f) {
  final p = Pool();
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

/// Does not manage it's resources.
class Unmanaged implements ResourceManager {
  /// Allocates memory on the native heap.
  ///
  /// For POSIX-based systems, this uses malloc. On Windows, it uses HeapAlloc
  /// against the default public heap. Allocation of either element size or count
  /// of 0 is undefined.
  ///
  /// Throws an ArgumentError on failure to allocate.
  Pointer<T> allocate<T extends NativeType>({int count = 1}) =>
      packageFfi.allocate(count: count);

  /// Releases memory on the native heap.
  ///
  /// For POSIX-based systems, this uses free. On Windows, it uses HeapFree
  /// against the default public heap. It may only be used against pointers
  /// allocated in a manner equivalent to [allocate].
  ///
  /// Throws an ArgumentError on failure to free.
  ///
  void free(Pointer pointer) => packageFfi.free(pointer);
}

/// Does not manage it's resources.
final Unmanaged unmanaged = Unmanaged();

extension Utf8InPool on String {
  /// Convert a [String] to a Utf8-encoded null-terminated C string.
  ///
  /// If 'string' contains NULL bytes, the converted string will be truncated
  /// prematurely. Unpaired surrogate code points in [string] will be preserved
  /// in the UTF-8 encoded result. See [Utf8Encoder] for details on encoding.
  ///
  /// Returns a malloc-allocated pointer to the result.
  ///
  /// The memory is managed by the [Pool] passed in as [pool].
  Pointer<Utf8> toUtf8(ResourceManager pool) {
    final units = utf8.encode(this);
    final Pointer<Uint8> result = pool.allocate<Uint8>(count: units.length + 1);
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }
}

extension Utf8Helpers on Pointer<Utf8> {
  /// Returns the length of a null-terminated string -- the number of (one-byte)
  /// characters before the first null byte.
  int strlen() {
    final Pointer<Uint8> array = this.cast<Uint8>();
    final Uint8List nativeString = array.asTypedList(_maxSize);
    return nativeString.indexWhere((char) => char == 0);
  }

  /// Creates a [String] containing the characters UTF-8 encoded in [this].
  ///
  /// [this] must be a zero-terminated byte sequence of valid UTF-8
  /// encodings of Unicode code points. It may also contain UTF-8 encodings of
  /// unpaired surrogate code points, which is not otherwise valid UTF-8, but
  /// which may be created when encoding a Dart string containing an unpaired
  /// surrogate. See [Utf8Decoder] for details on decoding.
  ///
  /// Returns a Dart string containing the decoded code points.
  String contents() {
    final int length = strlen();
    return utf8.decode(Uint8List.view(
        this.cast<Uint8>().asTypedList(length).buffer, 0, length));
  }
}

const int _kMaxSmi64 = (1 << 62) - 1;
const int _kMaxSmi32 = (1 << 30) - 1;
final int _maxSize = sizeOf<IntPtr>() == 8 ? _kMaxSmi64 : _kMaxSmi32;
