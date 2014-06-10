// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library index.lru_cache;

import 'dart:collection';


/**
 * This handler is notified when an item is evicted from the cache.
 */
typedef EvictionHandler<K, V>(K key, V value);

/**
 * A hash-table based cache implementation.
 *
 * When it reaches the specified number of items, the item that has not been
 * accessed (both get and put) recently is evicted.
 */
class LRUCache<K, V> {
  final LinkedHashSet<K> _lastKeys = new LinkedHashSet<K>();
  final HashMap<K, V> _map = new HashMap<K, V>();
  final int _maxSize;
  final EvictionHandler _handler;

  LRUCache(this._maxSize, [this._handler]);

  /**
   * Returns the value for the given [key] or null if [key] is not
   * in the cache.
   */
  V get(K key) {
    V value = _map[key];
    if (value != null) {
      _lastKeys.remove(key);
      _lastKeys.add(key);
    }
    return value;
  }

  /**
   * Removes the association for the given [key].
   */
  void remove(K key) {
    _lastKeys.remove(key);
    _map.remove(key);
  }

  /**
   * Associates the [key] with the given [value].
   *
   * If the cache is full, an item that has not been accessed recently is
   * evicted.
   */
  void put(K key, V value) {
    _lastKeys.remove(key);
    _lastKeys.add(key);
    if (_lastKeys.length > _maxSize) {
      K evictedKey = _lastKeys.first;
      V evictedValue = _map.remove(evictedKey);
      _lastKeys.remove(evictedKey);
      if (_handler != null) {
        _handler(evictedKey, evictedValue);
      }
    }
    _map[key] = value;
  }
}
