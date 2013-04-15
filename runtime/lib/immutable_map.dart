// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Immutable map class for compiler generated map literals.

class ImmutableMap<K, V> implements Map<K, V> {
  final _ImmutableArray kvPairs_;

  const ImmutableMap._create(_ImmutableArray keyValuePairs)
      : kvPairs_ = keyValuePairs;


  V operator [](K key) {
    // TODO(hausner): Since the keys are sorted, we could do a binary
    // search. But is it worth it?
    for (int i = 0; i < kvPairs_.length - 1; i += 2) {
      if (key == kvPairs_[i]) {
        return kvPairs_[i+1];
      }
    }
    return null;
  }

  bool get isEmpty {
    return kvPairs_.length == 0;
  }

  int get length {
    return kvPairs_.length ~/ 2;
  }

  void forEach(void f(K key, V value)) {
    for (int i = 0; i < kvPairs_.length; i += 2) {
      f(kvPairs_[i], kvPairs_[i+1]);
    }
  }

  Iterable<K> get keys {
    return new _ImmutableMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return new _ImmutableMapValueIterable<V>(this);
  }

  bool containsKey(K key) {
    for (int i = 0; i < kvPairs_.length; i += 2) {
      if (key == kvPairs_[i]) {
        return true;
      }
    }
    return false;
  }

  bool containsValue(V value) {
    for (int i = 1; i < kvPairs_.length; i += 2) {
      if (value == kvPairs_[i]) {
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

  V remove(K key) {
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
      _current = _map.kvPairs_[newIndex * 2];
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
      _current = _map.kvPairs_[newIndex * 2 + 1];
      return true;
    }
    _current = null;
    _index = _map.length;
    return false;
  }

  E get current => _current;
}
