// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

class ConstantMapView<K, V> extends UnmodifiableMapView implements ConstantMap {
  ConstantMapView(Map base) : super(base);
}

abstract class ConstantMap<K, V> implements Map<K, V> {
  // Used to create unmodifiable maps from other maps.
  factory ConstantMap.from(Map other) {
    List keys = other.keys.toList();
    bool allStrings = true;
    for (var k in keys) {
      if (k is! String) {
        allStrings = false;
        break;
      }
    }
    if (allStrings) {
      bool containsProto = false;
      var protoValue = null;
      var object = JS('=Object', '{}');
      int length = 0;
      for (var k in keys) {
        var v = other[k];
        if (k != '__proto__') {
          if (!jsHasOwnProperty(object, k)) length++;
          JS('void', '#[#] = #', object, k, v);
        } else {
          containsProto = true;
          protoValue = v;
        }
      }
      if (containsProto) {
        length++;
        return new ConstantProtoMap<K, V>._(length, object, keys, protoValue);
      }
      return new ConstantStringMap<K, V>._(length, object, keys);
    }
    // TODO(lrn): Make a proper unmodifiable map implementation.
    return new ConstantMapView<K, V>(new Map.from(other));
  }

  const ConstantMap._();

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  String toString() => Maps.mapToString(this);

  static _throwUnmodifiable() {
    throw new UnsupportedError('Cannot modify unmodifiable Map');
  }

  void operator []=(K key, V val) => _throwUnmodifiable();
  V putIfAbsent(K key, V ifAbsent()) => _throwUnmodifiable();
  V remove(K key) => _throwUnmodifiable();
  void clear() => _throwUnmodifiable();
  void addAll(Map<K, V> other) => _throwUnmodifiable();
}

class ConstantStringMap<K, V> extends ConstantMap<K, V> {
  // This constructor is not used for actual compile-time constants.
  // The instantiation of constant maps is shortcut by the compiler.
  const ConstantStringMap._(this._length, this._jsObject, this._keys)
      : super._();

  // TODO(18131): Ensure type inference knows the precise types of the fields.
  final int _length;
  // A constant map is backed by a JavaScript object.
  final _jsObject;
  final List<K> _keys;

  int get length => JS('JSUInt31', '#', _length);
  List get _keysArray => JS('JSUnmodifiableArray', '#', _keys);

  bool containsValue(Object needle) {
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
    // Use a JS 'cast' to get efficient loop.  Type inference doesn't get this
    // since constant map representation is chosen after type inference and the
    // instantiation is shortcut by the compiler.
    var keys = _keysArray;
    for (int i = 0; i < keys.length; i++) {
      var key = keys[i];
      f(key, _fetch(key));
    }
  }

  Iterable<K> get keys {
    return new _ConstantMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return new MappedIterable<K, V>(_keysArray, (key) => _fetch(key));
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

class _ConstantMapKeyIterable<K> extends Iterable<K> {
  ConstantStringMap<K, dynamic> _map;
  _ConstantMapKeyIterable(this._map);

  Iterator<K> get iterator => _map._keysArray.iterator;

  int get length => _map._keysArray.length;
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
    LinkedHashMap<K, V> backingMap = JS('LinkedHashMap|Null', r'#.$map', this);
    if (backingMap == null) {
      backingMap = new JsLinkedHashMap<K, V>();
      fillLiteralMap(_jsData, backingMap);
      JS('', r'#.$map = #', this, backingMap);
    }
    return backingMap;
  }

  bool containsValue(Object needle) {
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
