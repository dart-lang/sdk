// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

abstract class ConstantMap<K, V> implements Map<K, V> {
  const ConstantMap._();

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

class ConstantStringMap<K, V> extends ConstantMap<K, V>
                              implements _symbol_dev.EfficientLength {

  // This constructor is not used.  The instantiation is shortcut by the
  // compiler. It is here to make the uninitialized final fields legal.
  const ConstantStringMap._(this.length, this._jsObject, this._keys)
      : super._();

  final int length;
  // A constant map is backed by a JavaScript object.
  final _jsObject;
  final List<K> _keys;

  bool containsValue(V needle) {
    return values.any((V value) => value == needle);
  }

  bool containsKey(Object key) {
    if (key is! String) return false;
    if ('__proto__' == key) return false;
    return jsHasOwnProperty(_jsObject, key);
  }

  V operator [](Object key) {
    if (!containsKey(key)) return null;
    return _fetch(key);
  }

  // [_fetch] is the indexer for keys for which `containsKey(key)` is true.
  _fetch(key) => jsPropertyAccess(_jsObject, key);

  void forEach(void f(K key, V value)) {
    // Use a JS 'cast' to get efficient loop.  Type inferrence doesn't get this
    // since constant map representation is chosen after type inferrence and the
    // instantiation is shortcut by the compiler.
    var keys = JS('JSArray', '#', _keys);
    for (int i = 0; i < keys.length; i++) {
      var key = keys[i];
      f(key, _fetch(key));
    }
  }

  Iterable<K> get keys {
    return new _ConstantMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return new MappedIterable<K, V>(_keys, (key) => _fetch(key));
  }
}

class ConstantProtoMap<K, V> extends ConstantStringMap<K, V> {
  // This constructor is not used.  The instantiation is shortcut by the
  // compiler. It is here to make the uninitialized final fields legal.
  ConstantProtoMap._(length, jsObject, keys, this._protoValue)
      : super._(length, jsObject, keys);

  final V _protoValue;

  bool containsKey(Object key) {
    if (key is! String) return false;
    if ('__proto__' == key) return true;
    return jsHasOwnProperty(_jsObject, key);
  }

  _fetch(key) =>
      '__proto__' == key ? _protoValue : jsPropertyAccess(_jsObject, key);
}

class _ConstantMapKeyIterable<K> extends IterableBase<K> {
  ConstantStringMap<K, dynamic> _map;
  _ConstantMapKeyIterable(this._map);

  Iterator<K> get iterator => _map._keys.iterator;
}

class GeneralConstantMap<K, V> extends ConstantMap<K, V> {
  // This constructor is not used.  The instantiation is shortcut by the
  // compiler. It is here to make the uninitialized final fields legal.
  GeneralConstantMap(this._jsData) : super._();

  // [_jsData] holds a key-value pair list.
  final _jsData;

  // We cannot create the backing map on creation since hashCode interceptors
  // have not been defined when constants are created.
  Map<K, V> _getMap() {
    if (JS('bool', r'!this.$map')) {
      Map backingMap = new LinkedHashMap<K, V>();
      JS('', r'this.$map = #', fillLiteralMap(_jsData, backingMap));
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

  int get length => _getMap().length;
}
