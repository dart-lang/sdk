// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * Base class for implementing a [Map].
 *
 * This class has a basic implementation of all but five of the members of
 * [Map].
 * A basic `Map` class can be implemented by extending this class and
 * implementing `keys`, `operator[]`, `operator[]=`, `remove` and `clear`.
 * The remaining operations are implemented in terms of these five.
 *
 * The `keys` iterable should have efficient [Iterable.length] and
 * [Iterable.contains] operations, and it should catch concurrent modifications
 * of the keys while iterating.
 *
 * A more efficient implementation is usually possible by overriding
 * some of the other members as well.
 */
abstract class MapBase<K, V> extends MapMixin<K, V> {
  static String mapToString(Map m) {
    // Reuses the list in IterableBase for detecting toString cycles.
    if (_isToStringVisiting(m)) {
      return '{...}';
    }

    var result = new StringBuffer();
    try {
      _toStringVisiting.add(m);
      result.write('{');
      bool first = true;
      m.forEach((k, v) {
        if (!first) {
          result.write(', ');
        }
        first = false;
        result.write(k);
        result.write(': ');
        result.write(v);
      });
      result.write('}');
    } finally {
      assert(identical(_toStringVisiting.last, m));
      _toStringVisiting.removeLast();
    }

    return result.toString();
  }

  static _id(x) => x;

  /**
   * Fills a [Map] with key/value pairs computed from [iterable].
   *
   * This method is used by [Map] classes in the named constructor
   * `fromIterable`.
   */
  static void _fillMapWithMappedIterable(
      Map map, Iterable iterable, key(element), value(element)) {
    key ??= _id;
    value ??= _id;

    for (var element in iterable) {
      map[key(element)] = value(element);
    }
  }

  /**
   * Fills a map by associating the [keys] to [values].
   *
   * This method is used by [Map] classes in the named constructor
   * `fromIterables`.
   */
  static void _fillMapWithIterables(Map map, Iterable keys, Iterable values) {
    Iterator keyIterator = keys.iterator;
    Iterator valueIterator = values.iterator;

    bool hasNextKey = keyIterator.moveNext();
    bool hasNextValue = valueIterator.moveNext();

    while (hasNextKey && hasNextValue) {
      map[keyIterator.current] = valueIterator.current;
      hasNextKey = keyIterator.moveNext();
      hasNextValue = valueIterator.moveNext();
    }

    if (hasNextKey || hasNextValue) {
      throw new ArgumentError("Iterables do not have same length.");
    }
  }
}

/**
 * Mixin implementing a [Map].
 *
 * This mixin has a basic implementation of all but five of the members of
 * [Map].
 * A basic `Map` class can be implemented by mixin in this class and
 * implementing `keys`, `operator[]`, `operator[]=`, `remove` and `clear`.
 * The remaining operations are implemented in terms of these five.
 *
 * The `keys` iterable should have efficient [Iterable.length] and
 * [Iterable.contains] operations, and it should catch concurrent modifications
 * of the keys while iterating.
 *
 * A more efficient implementation is usually possible by overriding
 * some of the other members as well.
 */
abstract class MapMixin<K, V> implements Map<K, V> {
  Iterable<K> get keys;
  V operator [](Object key);
  operator []=(K key, V value);
  V remove(Object key);
  // The `clear` operation should not be based on `remove`.
  // It should clear the map even if some keys are not equal to themselves.
  void clear();

  Map<RK, RV> cast<RK, RV>() {
    Map<Object, Object> self = this;
    return self is Map<RK, RV> ? self : Map.castFrom<K, V, RK, RV>(this);
  }

  Map<RK, RV> retype<RK, RV>() => Map.castFrom<K, V, RK, RV>(this);

  void forEach(void action(K key, V value)) {
    for (K key in keys) {
      action(key, this[key]);
    }
  }

  void addAll(Map<K, V> other) {
    for (K key in other.keys) {
      this[key] = other[key];
    }
  }

  bool containsValue(Object value) {
    for (K key in keys) {
      if (this[key] == value) return true;
    }
    return false;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) {
      return this[key];
    }
    return this[key] = ifAbsent();
  }

  V update(K key, V update(V value), {V ifAbsent()}) {
    if (this.containsKey(key)) {
      return this[key] = update(this[key]);
    }
    if (ifAbsent != null) {
      return this[key] = ifAbsent();
    }
    throw new ArgumentError.value(key, "key", "Key not in map.");
  }

  void updateAll(V update(K key, V value)) {
    for (var key in this.keys) {
      this[key] = update(key, this[key]);
    }
  }

  Iterable<MapEntry<K, V>> get entries {
    return keys.map((K key) => new MapEntry<K, V>(key, this[key]));
  }

  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> transform(K key, V value)) {
    var result = <K2, V2>{};
    for (var key in this.keys) {
      var entry = transform(key, this[key]);
      result[entry.key] = entry.value;
    }
    return result;
  }

  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    for (var entry in newEntries) {
      this[entry.key] = entry.value;
    }
  }

  void removeWhere(bool test(K key, V value)) {
    var keysToRemove = <K>[];
    for (var key in keys) {
      if (test(key, this[key])) keysToRemove.add(key);
    }
    for (var key in keysToRemove) {
      this.remove(key);
    }
  }

  bool containsKey(Object key) => keys.contains(key);
  int get length => keys.length;
  bool get isEmpty => keys.isEmpty;
  bool get isNotEmpty => keys.isNotEmpty;
  Iterable<V> get values => new _MapBaseValueIterable<K, V>(this);
  String toString() => MapBase.mapToString(this);
}

/**
 * Basic implementation of an unmodifiable [Map].
 *
 * This class has a basic implementation of all but two of the members of
 * an umodifiable [Map].
 * A simple unmodifiable `Map` class can be implemented by extending this
 * class and implementing `keys` and `operator[]`.
 *
 * Modifying operations throw when used.
 * The remaining non-modifying operations are implemented in terms of `keys`
 * and `operator[]`.
 *
 * The `keys` iterable should have efficient [Iterable.length] and
 * [Iterable.contains] operations, and it should catch concurrent modifications
 * of the keys while iterating.
 *
 * A more efficient implementation is usually possible by overriding
 * some of the other members as well.
 */
abstract class UnmodifiableMapBase<K, V> = MapBase<K, V>
    with _UnmodifiableMapMixin<K, V>;

/**
 * Implementation of [Map.values] based on the map and its [Map.keys] iterable.
 *
 * Iterable that iterates over the values of a `Map`.
 * It accesses the values by iterating over the keys of the map, and using the
 * map's `operator[]` to lookup the keys.
 */
class _MapBaseValueIterable<K, V> extends EfficientLengthIterable<V> {
  final Map<K, V> _map;
  _MapBaseValueIterable(this._map);

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  V get first => _map[_map.keys.first];
  V get single => _map[_map.keys.single];
  V get last => _map[_map.keys.last];

  Iterator<V> get iterator => new _MapBaseValueIterator<K, V>(_map);
}

/**
 * Iterator created by [_MapBaseValueIterable].
 *
 * Iterates over the values of a map by iterating its keys and lookup up the
 * values.
 */
class _MapBaseValueIterator<K, V> implements Iterator<V> {
  final Iterator<K> _keys;
  final Map<K, V> _map;
  V _current = null;

  _MapBaseValueIterator(Map<K, V> map)
      : _map = map,
        _keys = map.keys.iterator;

  bool moveNext() {
    if (_keys.moveNext()) {
      _current = _map[_keys.current];
      return true;
    }
    _current = null;
    return false;
  }

  V get current => _current;
}

/**
 * Mixin that overrides mutating map operations with implementations that throw.
 */
abstract class _UnmodifiableMapMixin<K, V> implements Map<K, V> {
  /** This operation is not supported by an unmodifiable map. */
  void operator []=(K key, V value) {
    throw new UnsupportedError("Cannot modify unmodifiable map");
  }

  /** This operation is not supported by an unmodifiable map. */
  void addAll(Map<K, V> other) {
    throw new UnsupportedError("Cannot modify unmodifiable map");
  }

  /** This operation is not supported by an unmodifiable map. */
  void clear() {
    throw new UnsupportedError("Cannot modify unmodifiable map");
  }

  /** This operation is not supported by an unmodifiable map. */
  V remove(Object key) {
    throw new UnsupportedError("Cannot modify unmodifiable map");
  }

  /** This operation is not supported by an unmodifiable map. */
  V putIfAbsent(K key, V ifAbsent()) {
    throw new UnsupportedError("Cannot modify unmodifiable map");
  }
}

/**
 * Wrapper around a class that implements [Map] that only exposes `Map` members.
 *
 * A simple wrapper that delegates all `Map` members to the map provided in the
 * constructor.
 *
 * Base for delegating map implementations like [UnmodifiableMapView].
 */
class MapView<K, V> implements Map<K, V> {
  final Map<K, V> _map;
  const MapView(Map<K, V> map) : _map = map;

  Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();

  Map<RK, RV> retype<RK, RV>() => _map.retype<RK, RV>();

  V operator [](Object key) => _map[key];
  void operator []=(K key, V value) {
    _map[key] = value;
  }

  void addAll(Map<K, V> other) {
    _map.addAll(other);
  }

  void clear() {
    _map.clear();
  }

  V putIfAbsent(K key, V ifAbsent()) => _map.putIfAbsent(key, ifAbsent);
  bool containsKey(Object key) => _map.containsKey(key);
  bool containsValue(Object value) => _map.containsValue(value);
  void forEach(void action(K key, V value)) {
    _map.forEach(action);
  }

  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  int get length => _map.length;
  Iterable<K> get keys => _map.keys;
  V remove(Object key) => _map.remove(key);
  String toString() => _map.toString();
  Iterable<V> get values => _map.values;

  Iterable<MapEntry<K, V>> get entries => _map.entries;

  void addEntries(Iterable<Object> entries) {
    _map.addEntries(entries);
  }

  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> transform(K key, V value)) =>
      _map.map<K2, V2>(transform);

  V update(K key, V update(V value), {V ifAbsent()}) =>
      _map.update(key, update, ifAbsent: ifAbsent);

  void updateAll(V update(K key, V value)) {
    _map.updateAll(update);
  }

  void removeWhere(bool test(K key, V value)) {
    _map.removeWhere(test);
  }
}

/**
 * View of a [Map] that disallow modifying the map.
 *
 * A wrapper around a `Map` that forwards all members to the map provided in
 * the constructor, except for operations that modify the map.
 * Modifying operations throw instead.
 */
class UnmodifiableMapView<K, V> extends MapView<K, V>
    with _UnmodifiableMapMixin<K, V> {
  UnmodifiableMapView(Map<K, V> map) : super(map);

  Map<RK, RV> cast<RK, RV>() {
    Map<Object, Object> self = this;
    if (self is Map<RK, RV>) return self;
    return new UnmodifiableMapView<RK, RV>(_map.cast<RK, RV>());
  }

  Map<RK, RV> retype<RK, RV>() =>
      new UnmodifiableMapView<RK, RV>(_map.retype<RK, RV>());
}
