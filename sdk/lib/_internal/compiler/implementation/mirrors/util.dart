// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.mirrors.util;

import 'dart:collection' show Maps;

/**
 * An abstract map implementation. This class can be used as a superclass for
 * implementing maps, requiring only the further implementation of the
 * [:operator []:], [:forEach:] and [:length:] methods to provide a fully
 * implemented immutable map.
 */
// TODO(lrn): Consider using UnmodifiableBaseMap/UnmodifiableMapWrapper
// for these classes, or just rewrite for a bit more efficiency.
abstract class AbstractMap<K, V> implements Map<K, V> {
  AbstractMap();

  AbstractMap.from(Map<K, V> other) {
    other.forEach((k,v) => this[k] = v);
  }

  void operator []=(K key, value) {
    throw new UnsupportedError('[]= is not supported');
  }

  void clear() {
    throw new UnsupportedError('clear() is not supported');
  }

  void addAll(Map<K, V> other) {
    throw new UnsupportedError('addAll() is not supported');
  }

  bool containsKey(K key) {
    var found = false;
    forEach((k,_) {
      if (k == key) {
        found = true;
      }
    });
    return found;
  }

  bool containsValue(V value) {
    var found = false;
    forEach((_,v) {
      if (v == value) {
        found = true;
      }
    });
    return found;
  }

  Iterable<K> get keys {
    var keys = <K>[];
    forEach((k,_) => keys.add(k));
    return keys;
  }

  Iterable<V> get values {
    var values = <V>[];
    forEach((_,v) => values.add(v));
    return values;
  }

  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
  V putIfAbsent(K key, V ifAbsent()) {
    if (!containsKey(key)) {
      V value = this[key];
      this[key] = ifAbsent();
      return value;
    }
    return null;
  }

  V remove(K key) {
    throw new UnsupportedError('V remove(K key) is not supported');
  }

  String toString() => Maps.mapToString(this);
}

/**
 * [ImmutableMapWrapper] wraps a (mutable) map as an immutable map where all
 * mutating operations throw [UnsupportedError] upon invocation.
 */
class ImmutableMapWrapper<K, V> extends AbstractMap<K, V> {
  final Map<K, V> _map;

  ImmutableMapWrapper(this._map);

  int get length => _map.length;

  V operator [](K key) {
    if (key is K) {
      return _map[key];
    }
    return null;
  }

  void forEach(void f(K key, V value)) {
    _map.forEach(f);
  }
}

/**
 * A [Filter] function returns [:true:] iff [value] should be included.
 */
typedef bool Filter<V>(V value);

/**
 * An immutable map wrapper capable of filtering the input map.
 */
class FilteredImmutableMap<K, V> extends ImmutableMapWrapper<K, V> {
  final Filter<V> _filter;

  FilteredImmutableMap(Map<K, V> map, this._filter) : super(map);

  int get length {
    var count = 0;
    forEach((k,v) {
      count++;
    });
    return count;
  }

  void forEach(void f(K key, V value)) {
    _map.forEach((K k, V v) {
      if (_filter(v)) {
        f(k, v);
      }
    });
  }
}
