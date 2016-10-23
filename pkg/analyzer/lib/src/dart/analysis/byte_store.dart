// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/**
 * Store of bytes associated with string keys.
 *
 * Note that associations are not guaranteed to be persistent. The value
 * associated with a key can change or become `null` at any point of time.
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
 * [ByteStore] with LRU cache.
 */
class MemoryCachingByteStore implements ByteStore {
  final ByteStore store;
  final int maxEntries;

  final _map = <String, List<int>>{};
  final _keys = new LinkedHashSet<String>();

  MemoryCachingByteStore(this.store, this.maxEntries);

  @override
  List<int> get(String key) {
    _keys.remove(key);
    _keys.add(key);
    _evict();
    return _map.putIfAbsent(key, () => store.get(key));
  }

  @override
  void put(String key, List<int> bytes) {
    store.put(key, bytes);
    _map[key] = bytes;
    _keys.add(key);
    _evict();
  }

  void _evict() {
    if (_keys.length > maxEntries) {
      String key = _keys.first;
      _keys.remove(key);
      _map.remove(key);
    }
  }
}
