// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/byte_store/cache.dart';

/**
 * Store of bytes associated with string keys.
 *
 * Each key must be not longer than 100 characters and consist of only `[a-z]`,
 * `[0-9]`, `.` and `_` characters. The key cannot be an empty string, the
 * literal `.`, or contain the sequence `..`.
 *
 * Note that associations are not guaranteed to be persistent. The value
 * associated with a key can change or become `null` at any point in time.
 *
 * TODO(scheglov) Research using asynchronous API.
 */
abstract class ByteStore {
  /**
   * Return the bytes associated with the given [key].
   * Return `null` if the association does not exist.
   */
  List<int> get(String key);

  /**
   * Associate the given [bytes] with the [key].
   */
  void put(String key, List<int> bytes);
}

/**
 * [ByteStore] which stores data only in memory.
 */
class MemoryByteStore implements ByteStore {
  final Map<String, List<int>> _map = {};

  @override
  List<int> get(String key) {
    return _map[key];
  }

  @override
  void put(String key, List<int> bytes) {
    _map[key] = bytes;
  }
}

/**
 * A wrapper around [ByteStore] which adds an in-memory LRU cache to it.
 */
class MemoryCachingByteStore implements ByteStore {
  final ByteStore _store;
  final Cache<String, List<int>> _cache;

  MemoryCachingByteStore(this._store, int maxSizeBytes)
      : _cache = new Cache<String, List<int>>(maxSizeBytes, (v) => v.length);

  @override
  List<int> get(String key) {
    return _cache.get(key, () => _store.get(key));
  }

  @override
  void put(String key, List<int> bytes) {
    _store.put(key, bytes);
    _cache.put(key, bytes);
  }
}

/**
 * [ByteStore] which does not store any data.
 */
class NullByteStore implements ByteStore {
  @override
  List<int> get(String key) => null;

  @override
  void put(String key, List<int> bytes) {}
}
