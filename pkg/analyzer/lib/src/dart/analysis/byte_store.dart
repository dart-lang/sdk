// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/cache.dart';
import 'package:meta/meta.dart';

/// Store of bytes associated with string keys.
///
/// Each key must be not longer than 100 characters and consist of only `[a-z]`,
/// `[0-9]`, `.` and `_` characters. The key cannot be an empty string, the
/// literal `.`, or contain the sequence `..`.
///
/// Note that associations are not guaranteed to be persistent. The value
/// associated with a key can change or become `null` at any point in time.
abstract class ByteStore {
  /// Return the bytes associated with the given [key].
  /// Return `null` if the association does not exist.
  ///
  /// If this store supports reference counting, increments it.
  Uint8List? get(String key);

  /// Associate [bytes] with [key].
  ///
  /// If this store supports reference counting:
  /// 1. If there is already data with [key], increments the count and
  ///    returns the existing data. This can happen when multiple isolates work
  ///    with the same store (via native code).
  /// 2. Otherwise, returns the internalized version of [bytes], the reference
  ///    count is set to `1`.
  Uint8List putGet(String key, Uint8List bytes);

  /// If this store supports reference counting, decrements it for every key
  /// in [keys], and evicts entries with the reference count equal zero.
  void release(Iterable<String> keys);
}

/// [ByteStore] which stores data only in memory.
class MemoryByteStore implements ByteStore {
  @visibleForTesting
  final Map<String, MemoryByteStoreEntry> map = {};

  /// Throws [StateError] if [release] invoked when there is no entry.
  @visibleForTesting
  bool throwIfReleaseWithoutEntry = false;

  @override
  Uint8List? get(String key) {
    var entry = map[key];
    if (entry == null) {
      return null;
    }

    entry.refCount++;
    return entry.bytes;
  }

  @override
  Uint8List putGet(String key, Uint8List bytes) {
    var entry = map[key];
    if (entry != null) {
      entry.refCount++;
      return entry.bytes;
    }

    map[key] = MemoryByteStoreEntry._(bytes);
    return bytes;
  }

  @override
  void release(Iterable<String> keys) {
    for (var key in keys) {
      var entry = map[key];
      if (entry != null) {
        entry.refCount--;
        if (entry.refCount == 0) {
          map.remove(key);
        }
      } else if (throwIfReleaseWithoutEntry) {
        throw StateError('No entry: $key');
      }
    }
  }
}

@visibleForTesting
class MemoryByteStoreEntry {
  final Uint8List bytes;
  int refCount = 1;

  MemoryByteStoreEntry._(this.bytes);

  @override
  String toString() {
    return '(length: ${bytes.length}, refCount: $refCount)';
  }
}

/// A wrapper around [ByteStore] which adds an in-memory LRU cache to it.
class MemoryCachingByteStore implements ByteStore {
  final ByteStore _store;
  final Cache<String, Uint8List> _cache;

  MemoryCachingByteStore(this._store, int maxSizeBytes)
      : _cache = Cache<String, Uint8List>(maxSizeBytes, (v) => v.length);

  @override
  Uint8List? get(String key) {
    var cached = _cache.get(key);
    if (cached != null) {
      return cached;
    }

    var fromStore = _store.get(key);
    if (fromStore != null) {
      _cache.put(key, fromStore);
      return fromStore;
    }

    return null;
  }

  @override
  Uint8List putGet(String key, Uint8List bytes) {
    _store.putGet(key, bytes);
    _cache.put(key, bytes);
    return bytes;
  }

  @override
  void release(Iterable<String> keys) {}
}

/// [ByteStore] which does not store any data.
class NullByteStore implements ByteStore {
  @override
  Uint8List? get(String key) => null;

  @override
  Uint8List putGet(String key, Uint8List bytes) => bytes;

  @override
  void release(Iterable<String> keys) {}
}
