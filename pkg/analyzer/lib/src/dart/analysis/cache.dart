// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// LRU cache of objects.
class Cache<K, V> {
  final int _maxSizeBytes;
  final int Function(V) _meter;

  @visibleForTesting
  final map = <K, V>{};
  int _currentSizeBytes = 0;
  int _evictedBytes = 0;
  int _evictedEntryCount = 0;
  int _evictionCount = 0;

  Cache(this._maxSizeBytes, this._meter);

  int get currentSizeBytes => _currentSizeBytes;
  int get entryCount => map.length;
  int get evictedBytes => _evictedBytes;
  int get evictedEntryCount => _evictedEntryCount;
  int get evictionCount => _evictionCount;
  int get maxSizeBytes => _maxSizeBytes;

  V? get(K key) {
    var value = map.remove(key);
    if (value != null) {
      map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    V? oldValue = map[key];
    if (oldValue != null) {
      _currentSizeBytes -= _meter(oldValue);
    }
    map[key] = value;
    _currentSizeBytes += _meter(value);
    _evict();
  }

  void _evict() {
    if (_currentSizeBytes > _maxSizeBytes) {
      var keysToRemove = <K>[];
      var evictedBytes = 0;
      for (var entry in map.entries) {
        keysToRemove.add(entry.key);
        var entrySize = _meter(entry.value);
        _currentSizeBytes -= entrySize;
        evictedBytes += entrySize;
        if (_currentSizeBytes <= _maxSizeBytes) {
          break;
        }
      }
      for (var key in keysToRemove) {
        map.remove(key);
      }
      if (keysToRemove.isNotEmpty) {
        _evictionCount++;
        _evictedBytes += evictedBytes;
        _evictedEntryCount += keysToRemove.length;
      }
    }
  }
}
