// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

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
 * A wrapper around [ByteStore] which adds an in-memory LRU cache to it.
 */
class MemoryCachingByteStore implements ByteStore {
  final ByteStore _store;
  final int _maxSizeBytes;

  final _map = new LinkedHashMap<String, List<int>>();
  int _currentSizeBytes = 0;

  MemoryCachingByteStore(this._store, this._maxSizeBytes);

  @override
  List<int> get(String key) {
    List<int> bytes = _map.remove(key);
    if (bytes == null) {
      bytes = _store.get(key);
      _map[key] = bytes;
      _currentSizeBytes += bytes?.length ?? 0;
      _evict();
    } else {
      _map[key] = bytes;
    }
    return bytes;
  }

  @override
  void put(String key, List<int> bytes) {
    _store.put(key, bytes);
    _currentSizeBytes -= _map[key]?.length ?? 0;
    _map[key] = bytes;
    _currentSizeBytes += bytes.length;
    _evict();
  }

  void _evict() {
    while (_currentSizeBytes > _maxSizeBytes) {
      if (_map.isEmpty) {
        break;
      }
      String key = _map.keys.first;
      List<int> bytes = _map.remove(key);
      _currentSizeBytes -= bytes.length;
    }
  }
}
