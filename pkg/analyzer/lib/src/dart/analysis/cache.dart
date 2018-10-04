// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/**
 * LRU cache of objects.
 */
class Cache<K, V> {
  final int _maxSizeBytes;
  final int Function(V) _meter;

  final _map = new LinkedHashMap<K, V>();
  int _currentSizeBytes = 0;

  Cache(this._maxSizeBytes, this._meter);

  V get(K key, V getNotCached()) {
    V value = _map.remove(key);
    if (value == null) {
      value = getNotCached();
      if (value != null) {
        _map[key] = value;
        _currentSizeBytes += _meter(value);
        _evict();
      }
    } else {
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    V oldValue = _map[key];
    if (oldValue != null) {
      _currentSizeBytes -= _meter(oldValue);
    }
    _map[key] = value;
    _currentSizeBytes += _meter(value);
    _evict();
  }

  void _evict() {
    while (_currentSizeBytes > _maxSizeBytes) {
      if (_map.isEmpty) {
        // Should be impossible, since _currentSizeBytes should always match
        // _map.  But recover anyway.
        assert(false);
        _currentSizeBytes = 0;
        break;
      }
      K key = _map.keys.first;
      V value = _map.remove(key);
      _currentSizeBytes -= _meter(value);
    }
  }
}
