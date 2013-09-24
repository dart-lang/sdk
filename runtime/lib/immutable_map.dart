// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Immutable map class for compiler generated map literals.

class ImmutableMap<K, V> implements Map<K, V> {
  final _ImmutableArray _kvPairs;

  const ImmutableMap._create(_ImmutableArray keyValuePairs)
      : _kvPairs = keyValuePairs;


  V operator [](Object key) {
    // TODO(hausner): Since the keys are sorted, we could do a binary
    // search. But is it worth it?
    for (int i = 0; i < _kvPairs.length - 1; i += 2) {
      if (key == _kvPairs[i]) {
        return _kvPairs[i+1];
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
      f(_kvPairs[i], _kvPairs[i+1]);
    }
  }

  Iterable<K> get keys {
    return new _ImmutableMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return new _ImmutableMapValueIterable<V>(this);
  }

  bool containsKey(Object key) {
    for (int i = 0; i < _kvPairs.length; i += 2) {
      if (key == _kvPairs[i]) {
        return true;
      }
    }
    return false;
  }

  bool containsValue(Object value) {
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

  V putIfAbsent(K key, V ifAbsent()) {
    throw new UnsupportedError("Cannot set value in unmodifiable Map");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear unmodifiable Map");
  }

  V remove(Object key) {
    throw new UnsupportedError("Cannot remove from unmodifiable Map");
  }

  String toString() {
    return Maps.mapToString(this);
  }
}

class _ImmutableMapKeyIterable<E> extends IterableBase<E> {
  final ImmutableMap _map;
  _ImmutableMapKeyIterable(this._map);

  Iterator<E> get iterator {
    return new _ImmutableMapKeyIterator<E>(_map);
  }
}

class _ImmutableMapValueIterable<E> extends IterableBase<E> {
  final ImmutableMap _map;
  _ImmutableMapValueIterable(this._map);

  Iterator<E> get iterator {
    return new _ImmutableMapValueIterator<E>(_map);
  }
}

class _ImmutableMapKeyIterator<E> implements Iterator<E> {
  ImmutableMap _map;
  int _index = -1;
  E _current;

  _ImmutableMapKeyIterator(this._map);

  bool moveNext() {
    int newIndex = _index + 1;
    if (newIndex < _map.length) {
      _index = newIndex;
      _current = _map._kvPairs[newIndex * 2];
      return true;
    }
    _current = null;
    _index = _map.length;
    return false;
  }

  E get current => _current;
}

class _ImmutableMapValueIterator<E> implements Iterator<E> {
  ImmutableMap _map;
  int _index = -1;
  E _current;

  _ImmutableMapValueIterator(this._map);

  bool moveNext() {
    int newIndex = _index + 1;
    if (newIndex < _map.length) {
      _index = newIndex;
      _current = _map._kvPairs[newIndex * 2 + 1];
      return true;
    }
    _current = null;
    _index = _map.length;
    return false;
  }

  E get current => _current;
}
