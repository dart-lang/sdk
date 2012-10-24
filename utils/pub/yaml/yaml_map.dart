// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This class wraps behaves almost identically to the normal Dart Map
 * implementation, with the following differences:
 *
 * * It allows null, NaN, boolean, list, and map keys.
 * * It defines `==` structurally. That is, `yamlMap1 == yamlMap2` if they have
 *   the same contents.
 * * It has a compatible [hashCode] method.
 */
class YamlMap implements Map {
  Map _map;

  YamlMap() : _map = new Map();

  YamlMap.from(Map map) : _map = new Map.from(map);

  YamlMap._wrap(this._map);

  bool containsValue(value) => _map.containsValue(value);
  bool containsKey(key) => _map.containsKey(_wrapKey(key));
  operator [](key) => _map[_wrapKey(key)];
  operator []=(key, value) { _map[_wrapKey(key)] = value; }
  putIfAbsent(key, ifAbsent()) => _map.putIfAbsent(_wrapKey(key), ifAbsent);
  remove(key) => _map.remove(_wrapKey(key));
  void clear() => _map.clear();
  void forEach(void f(key, value)) =>
    _map.forEach((k, v) => f(_unwrapKey(k), v));
  Collection getKeys() => _map.getKeys().map(_unwrapKey);
  Collection getValues() => _map.getValues();
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  String toString() => _map.toString();

  int get hashCode => _hashCode(_map);

  bool operator ==(other) {
    if (other is! YamlMap) return false;
    return deepEquals(this, other);
  }

  /** Wraps an object for use as a key in the map. */
  _wrapKey(obj) {
    if (obj != null && obj is! bool && obj is! List &&
        (obj is! double || !obj.isNan()) &&
        (obj is! Map || obj is YamlMap)) {
      return obj;
    } else if (obj is Map) {
      return new YamlMap._wrap(obj);
    }
    return new _WrappedHashKey(obj);
  }

  /** Unwraps an object that was used as a key in the map. */
  _unwrapKey(obj) => obj is _WrappedHashKey ? obj.value : obj;
}

/**
 * A class for wrapping normally-unhashable objects that are being used as keys
 * in a YamlMap.
 */
class _WrappedHashKey {
  var value;

  _WrappedHashKey(this.value);

  int get hashCode => _hashCode(value);

  String toString() => value.toString();

  /** This is defined as both values being structurally equal. */
  bool operator ==(other) {
    if (other is! _WrappedHashKey) return false;
    return deepEquals(this.value, other.value);
  }
}

/**
 * Returns the hash code for [obj]. This includes null, true, false, maps, and
 * lists. Also handles self-referential structures.
 */
int _hashCode(obj, [List parents]) {
  if (parents == null) {
    parents = [];
  } else if (parents.some((p) => p === obj)) {
    return -1;
  }

  parents.add(obj);
  try {
    if (obj == null) return 0;
    if (obj == true) return 1;
    if (obj == false) return 2;
    if (obj is Map) {
      return _hashCode(obj.getKeys(), parents) ^
        _hashCode(obj.getValues(), parents);
    }
    if (obj is List) {
      // This is probably a really bad hash function, but presumably we'll get this
      // in the standard library before it actually matters.
      int hash = 0;
      for (var e in obj) {
        hash ^= _hashCode(e, parents);
      }
      return hash;
    }
    return obj.hashCode;
  } finally {
    parents.removeLast();
  }
}
