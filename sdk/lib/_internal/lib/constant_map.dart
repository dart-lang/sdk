// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

abstract class ConstantMap<K, V> implements Map<K, V> {
  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  String toString() => Maps.mapToString(this);

  _throwUnmodifiable() {
    throw new UnsupportedError("Cannot modify unmodifiable Map");
  }
  void operator []=(K key, V val) => _throwUnmodifiable();
  V putIfAbsent(K key, V ifAbsent()) => _throwUnmodifiable();
  V remove(K key) => _throwUnmodifiable();
  void clear() => _throwUnmodifiable();
  void addAll(Map<K, V> other) => _throwUnmodifiable();
}

// This class has no constructor. This is on purpose since the instantiation
// is shortcut by the compiler.
class ConstantStringMap<K, V> extends ConstantMap<K, V>
                              implements _symbol_dev.EfficientLength {
  final int length;
  // A constant map is backed by a JavaScript object.
  final _jsObject;
  final List<K> _keys;

  bool containsValue(V needle) {
    return values.any((V value) => value == needle);
  }

  bool containsKey(Object key) {
    if (key is! String) return false;
    if (key == '__proto__') return false;
    return jsHasOwnProperty(_jsObject, key);
  }

  V operator [](Object key) {
    if (key is! String) return null;
    if (!containsKey(key)) return null;
    return jsPropertyAccess(_jsObject, key);
  }

  void forEach(void f(K key, V value)) {
    _keys.forEach((key) => f(key, this[key]));
  }

  Iterable<K> get keys {
    return new _ConstantMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return _keys.map((key) => this[key]);
  }
}

// This class has no constructor. This is on purpose since the instantiation
// is shortcut by the compiler.
class ConstantProtoMap<K, V> extends ConstantStringMap<K, V> {
  final V _protoValue;

  bool containsKey(Object key) {
    if (key == '__proto__') return true;
    return super.containsKey(key);
  }

  V operator [](Object key) {
    if (key == '__proto__') return _protoValue;
    return super[key];
  }
}

class _ConstantMapKeyIterable<K> extends IterableBase<K> {
  ConstantStringMap<K, dynamic> _map;
  _ConstantMapKeyIterable(this._map);

  Iterator<K> get iterator => _map._keys.iterator;
}

// This class has no constructor. This is on purpose since the instantiation
// is shortcut by the compiler.
class GeneralConstantMap<K, V> extends ConstantMap<K, V> {
  // [_jsData] holds a key-value pair list.
  final _jsData;

  // We cannot create the backing map on creation since hashCode interceptors
  // have not been defined when constants are created.
  Map<K, V> _getMap() {
    if (JS('bool', r'!this.$map')) {
      JS('', r'this.$map = #', makeConstantMap(_jsData));
    }
    return JS('Map', r'this.$map');
  }

  bool containsValue(V needle) {
    return _getMap().containsValue(needle);
  }

  bool containsKey(Object key) {
    return _getMap().containsKey(key);
  }

  V operator [](Object key) {
    return _getMap()[key];
  }

  void forEach(void f(K key, V value)) {
    _getMap().forEach(f);
  }

  Iterable<K> get keys {
    return _getMap().keys;
  }

  Iterable<V> get values {
    return _getMap().values;
  }
}
