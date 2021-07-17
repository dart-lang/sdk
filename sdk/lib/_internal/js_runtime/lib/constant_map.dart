// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

class ConstantMapView<K, V> extends UnmodifiableMapView<K, V>
    implements ConstantMap<K, V> {
  ConstantMapView(Map<K, V> base) : super(base);
}

abstract class ConstantMap<K, V> implements Map<K, V> {
  // Used to create unmodifiable maps from other maps.
  factory ConstantMap.from(Map other) {
    final keys = List<K>.from(other.keys);
    bool allStrings = true;
    for (var k in keys) {
      if (k is! String || '__proto__' == k) {
        allStrings = false;
        break;
      }
    }
    if (allStrings) {
      var object = JS('=Object', '{}');
      for (final k in keys) {
        V v = other[k];
        JS('void', '#[#] = #', object, k, v);
      }
      return ConstantStringMap<K, V>._(keys.length, object, keys);
    }
    // TODO(lrn): Make a proper unmodifiable map implementation.
    return ConstantMapView<K, V>(Map.from(other));
  }

  const ConstantMap._();

  Map<RK, RV> cast<RK, RV>() => Map.castFrom<K, V, RK, RV>(this);
  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  String toString() => MapBase.mapToString(this);

  static Never _throwUnmodifiable() {
    throw UnsupportedError('Cannot modify unmodifiable Map');
  }

  void operator []=(K key, V val) {
    _throwUnmodifiable();
  }

  V putIfAbsent(K key, V ifAbsent()) {
    _throwUnmodifiable();
  }

  V? remove(Object? key) {
    _throwUnmodifiable();
  }

  void clear() {
    _throwUnmodifiable();
  }

  void addAll(Map<K, V> other) {
    _throwUnmodifiable();
  }

  Iterable<MapEntry<K, V>> get entries sync* {
    // `this[key]` has static type `V?` but is always `V`. Rather than `as V`,
    // we use `as dynamic` so the upcast requires no checking and the implicit
    // downcast to `V` will be discarded in production.
    for (var key in keys) yield MapEntry<K, V>(key, this[key] as dynamic);
  }

  void addEntries(Iterable<MapEntry<K, V>> entries) {
    for (var entry in entries) this[entry.key] = entry.value;
  }

  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> transform(K key, V value)) {
    var result = <K2, V2>{};
    this.forEach((K key, V value) {
      var entry = transform(key, value);
      result[entry.key] = entry.value;
    });
    return result;
  }

  V update(K key, V update(V value), {V ifAbsent()?}) {
    _throwUnmodifiable();
  }

  void updateAll(V update(K key, V value)) {
    _throwUnmodifiable();
  }

  void removeWhere(bool test(K key, V value)) {
    _throwUnmodifiable();
  }
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
  List<K> get _keysArray => JS('JSUnmodifiableArray', '#', _keys);

  bool containsValue(Object? needle) {
    return values.any((V value) => value == needle);
  }

  bool containsKey(Object? key) {
    if (key is! String) return false;
    if ('__proto__' == key) return false;
    return jsHasOwnProperty(_jsObject, key);
  }

  V? operator [](Object? key) {
    if (!containsKey(key)) return null;
    return JS('', '#', _fetch(key));
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
    return _ConstantMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return MappedIterable<K, V>(_keysArray, (key) => _fetch(key));
  }
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
    LinkedHashMap<K, V>? backingMap = JS('LinkedHashMap|Null', r'#.$map', this);
    if (backingMap == null) {
      backingMap = LinkedHashMap<K, V>(
          hashCode: _constantMapHashCode,
          // In legacy mode (--no-sound-null-safety), `null` keys are
          // permitted. In sound mode, `null` keys are permitted only if [K] is
          // nullable.
          isValidKey: JS_GET_FLAG('LEGACY') ? _typeTest<K?>() : _typeTest<K>());
      fillLiteralMap(_jsData, backingMap);
      JS('', r'#.$map = #', this, backingMap);
    }
    return backingMap;
  }

  static int _constantMapHashCode(Object? key) {
    // Types are tested here one-by-one so that each call to get:hashCode can be
    // resolved differently.

    // Some common primitives in a GeneralConstantMap.
    if (key is num) return key.hashCode; // One method on JSNumber.

    // Specially handled known types.
    if (key is Symbol) return key.hashCode;
    if (key is Type) return key.hashCode;

    // Everything else, including less common primitives.
    return identityHashCode(key);
  }

  static bool Function(Object?) _typeTest<T>() => (Object? o) => o is T;

  bool containsValue(Object? needle) {
    return _getMap().containsValue(needle);
  }

  bool containsKey(Object? key) {
    return _getMap().containsKey(key);
  }

  V? operator [](Object? key) {
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
