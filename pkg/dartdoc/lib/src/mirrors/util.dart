// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('util');

/**
 * An abstract map implementation. This class can be used as a superclass for
 * implementing maps, requiring only the further implementation of the
 * [:operator []:], [:forEach:] and [:length:] methods to provide a fully
 * implemented immutable map.
 */
abstract class AbstractMap<K,V> implements Map<K,V> {
  AbstractMap();

  AbstractMap.from(Map<K,V> other) {
    other.forEach((k,v) => this[k] = v);
  }

  void operator []=(K key, value) {
    throw new UnsupportedError('[]= is not supported');
  }

  void clear() {
    throw new UnsupportedError('clear() is not supported');
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

  Collection<K> get keys {
    var keys = <K>[];
    forEach((k,_) => keys.add(k));
    return keys;
  }

  Collection<V> get values {
    var values = <V>[];
    forEach((_,v) => values.add(v));
    return values;
  }

  bool get isEmpty => length == 0;
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
}

/**
 * [ImmutableMapWrapper] wraps a (mutable) map as an immutable map where all
 * mutating operations throw [UnsupportedError] upon invocation.
 */
class ImmutableMapWrapper<K,V> extends AbstractMap<K,V> {
  final Map<K,V> _map;

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
class FilteredImmutableMap<K,V> extends ImmutableMapWrapper<K,V> {
  final Filter<V> _filter;

  FilteredImmutableMap(Map<K,V> map, this._filter) : super(map);

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

/**
 * An [AsFilter] takes a [value] of type [V1] and returns [value] iff it is of
 * type [V2] or [:null:] otherwise. An [AsFilter] therefore behaves like the
 * [:as:] expression.
 */
typedef V2 AsFilter<V1, V2>(V1 value);

/**
 * An immutable map wrapper capable of filtering the input map based on types.
 * It takes an [AsFilter] function which converts the original values of type
 * [Vin] into values of type [Vout], or returns [:null:] if the value should
 * not be included in the filtered map.
 */
class AsFilteredImmutableMap<K, Vin, Vout> extends AbstractMap<K, Vout> {
  final Map<K, Vin> _map;
  final AsFilter<Vin, Vout> _filter;

  AsFilteredImmutableMap(this._map, this._filter);

  int get length {
    var count = 0;
    forEach((k,v) {
      count++;
    });
    return count;
  }

  Vout operator [](K key) {
    if (key is K) {
      Vin value = _map[key];
      if (value != null) {
        return _filter(value);
      }
    }
    return null;
  }

  void forEach(void f(K key, Vout value)) {
    _map.forEach((K k, Vin v) {
      var value = _filter(v);
      if (value != null) {
        f(k, value);
      }
    });
  }
}
