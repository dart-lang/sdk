// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

/// Immutable map class for compiler generated map literals.
// TODO(lrn): Extend MapBase with UnmodifiableMapMixin when mixins
// support forwarding const constructors.
@pragma("vm:entry-point")
class _ImmutableMap<K, V> implements Map<K, V> {
  final _ImmutableList _kvPairs;

  @pragma("vm:entry-point")
  const _ImmutableMap._create(_ImmutableList keyValuePairs)
      : _kvPairs = keyValuePairs;

  Map<K2, V2> cast<K2, V2>() => Map.castFrom<K, V, K2, V2>(this);
  V? operator [](Object? key) {
    // To preserve the key-value order of the map literal, the keys are
    // not sorted. Need to do linear search or implement an additional
    // lookup table.
    for (int i = 0; i < _kvPairs.length - 1; i += 2) {
      if (key == _kvPairs[i]) {
        return _kvPairs[i + 1];
      }
    }
    return null;
  }

  bool get isEmpty {
    return _kvPairs.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  int get length {
    return _kvPairs.length ~/ 2;
  }

  void forEach(void f(K key, V value)) {
    for (int i = 0; i < _kvPairs.length; i += 2) {
      f(_kvPairs[i], _kvPairs[i + 1]);
    }
  }

  Iterable<K> get keys {
    return new _ImmutableMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return new _ImmutableMapValueIterable<V>(this);
  }

  bool containsKey(Object? key) {
    for (int i = 0; i < _kvPairs.length; i += 2) {
      if (key == _kvPairs[i]) {
        return true;
      }
    }
    return false;
  }

  bool containsValue(Object? value) {
    for (int i = 1; i < _kvPairs.length; i += 2) {
      if (value == _kvPairs[i]) {
        return true;
      }
    }
    return false;
  }

  void operator []=(K key, V value) {
    throw new UnsupportedError("Cannot set value in unmodifiable Map");
  }

  void addAll(Map<K, V> other) {
    throw new UnsupportedError("Cannot set value in unmodifiable Map");
  }

  V putIfAbsent(K key, V ifAbsent()) {
    throw new UnsupportedError("Cannot set value in unmodifiable Map");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear unmodifiable Map");
  }

  V? remove(Object? key) {
    throw new UnsupportedError("Cannot remove from unmodifiable Map");
  }

  Iterable<MapEntry<K, V>> get entries =>
      new _ImmutableMapEntryIterable<K, V>(this);

  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> f(K key, V value)) {
    var result = <K2, V2>{};
    for (int i = 0; i < _kvPairs.length; i += 2) {
      var entry = f(_kvPairs[i], _kvPairs[i + 1]);
      result[entry.key] = entry.value;
    }
    return result;
  }

  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    throw new UnsupportedError("Cannot modify an unmodifiable Map");
  }

  V update(K key, V update(V value), {V ifAbsent()?}) {
    throw new UnsupportedError("Cannot modify an unmodifiable Map");
  }

  void updateAll(V update(K key, V value)) {
    throw new UnsupportedError("Cannot modify an unmodifiable Map");
  }

  void removeWhere(bool predicate(K key, V value)) {
    throw new UnsupportedError("Cannot modify an unmodifiable Map");
  }

  String toString() => MapBase.mapToString(this);
}

class _ImmutableMapKeyIterable<E> extends EfficientLengthIterable<E> {
  final _ImmutableMap _map;
  _ImmutableMapKeyIterable(this._map);

  Iterator<E> get iterator {
    return new _ImmutableMapKeyIterator<E>(_map);
  }

  int get length => _map.length;
}

class _ImmutableMapValueIterable<E> extends EfficientLengthIterable<E> {
  final _ImmutableMap _map;
  _ImmutableMapValueIterable(this._map);

  Iterator<E> get iterator {
    return new _ImmutableMapValueIterator<E>(_map);
  }

  int get length => _map.length;
}

class _ImmutableMapEntryIterable<K, V>
    extends EfficientLengthIterable<MapEntry<K, V>> {
  final _ImmutableMap _map;
  _ImmutableMapEntryIterable(this._map);

  Iterator<MapEntry<K, V>> get iterator {
    return new _ImmutableMapEntryIterator<K, V>(_map);
  }

  int get length => _map.length;
}

class _ImmutableMapKeyIterator<E> implements Iterator<E> {
  _ImmutableMap _map;
  int _nextIndex = 0;
  E? _current;

  _ImmutableMapKeyIterator(this._map);

  bool moveNext() {
    int newIndex = _nextIndex;
    if (newIndex < _map.length) {
      _nextIndex = newIndex + 1;
      _current = _map._kvPairs[newIndex * 2];
      return true;
    }
    _current = null;
    return false;
  }

  E get current => _current as E;
}

class _ImmutableMapValueIterator<E> implements Iterator<E> {
  _ImmutableMap _map;
  int _nextIndex = 0;
  E? _current;

  _ImmutableMapValueIterator(this._map);

  bool moveNext() {
    int newIndex = _nextIndex;
    if (newIndex < _map.length) {
      _nextIndex = newIndex + 1;
      _current = _map._kvPairs[newIndex * 2 + 1];
      return true;
    }
    _current = null;
    return false;
  }

  E get current => _current as E;
}

class _ImmutableMapEntryIterator<K, V> implements Iterator<MapEntry<K, V>> {
  _ImmutableMap _map;
  int _nextIndex = 0;
  MapEntry<K, V>? _current;

  _ImmutableMapEntryIterator(this._map);

  bool moveNext() {
    int newIndex = _nextIndex;
    if (newIndex < _map.length) {
      _nextIndex = newIndex + 1;
      _current = new MapEntry<K, V>(
          _map._kvPairs[newIndex * 2], _map._kvPairs[newIndex * 2 + 1]);
      return true;
    }
    _current = null;
    return false;
  }

  MapEntry<K, V> get current => _current as MapEntry<K, V>;
}
