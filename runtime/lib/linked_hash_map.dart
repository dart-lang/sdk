// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-internalized implementation of a default-constructed LinkedHashMap.
// Currently calls the runtime for most operations.
class _InternalLinkedHashMap<K, V> implements HashMap<K, V>,
                                              LinkedHashMap<K, V> {
  factory _InternalLinkedHashMap() native "LinkedHashMap_allocate";
  int get length native "LinkedHashMap_getLength";
  V operator [](K key) native "LinkedHashMap_lookUp";
  void operator []=(K key, V value) native "LinkedHashMap_insertOrUpdate";
  V remove(K key) native "LinkedHashMap_remove";
  void clear() native "LinkedHashMap_clear";
  bool containsKey(K key) native "LinkedHashMap_containsKey";

  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;

  List _toArray() native "LinkedHashMap_toArray";

  // "Modificaton marks" are tokens used to detect concurrent modification.
  // Considering only modifications (M) and iterator creation (I) events, e.g.:
  //   M, M, M, I, I, M, I, M, M, I, I, I, M ...
  // a new mark is allocated at the start of each run of I's and cleared from
  // the map at the start of each run of M's. Iterators' moveNext check whether
  // the map's mark was changed or cleared since the iterator was created.
  // TODO(koda): Consider a counter instead.
  Object _getModMark(bool create) native "LinkedHashMap_getModMark";

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  V putIfAbsent(K key, Function ifAbsent) {
    if (containsKey(key)) {
      return this[key];
    } else {
      V value = ifAbsent();
      this[key] = value;
      return value;
    }
  }

  bool containsValue(V value) {
    for (V v in values) {
      if (v == value) {
        return true;
      }
    }
    return false;
  }

  void forEach(Function f) {
    for (K key in keys) {
      f(key, this[key]);
    }
  }

  // The even-indexed entries of toArray are the keys.
  Iterable<K> get keys =>
      new _ListStepIterable<K>(this, _getModMark(true), _toArray(), -2, 2);

  // The odd-indexed entries of toArray are the values.
  Iterable<V> get values =>
      new _ListStepIterable<V>(this, _getModMark(true), _toArray(), -1, 2);

  String toString() => Maps.mapToString(this);
}

// Iterates over a list from a given offset and step size.
class _ListStepIterable<E> extends IterableBase<E> {
  _InternalLinkedHashMap _map;
  Object _modMark;
  List _list;
  int _offset;
  int _step;

  _ListStepIterable(this._map, this._modMark,
                    this._list, this._offset, this._step);

  Iterator<E> get iterator =>
      new _ListStepIterator(_map, _modMark, _list, _offset, _step);

  // TODO(koda): Should this check for concurrent modification?
  int get length => _map.length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
}

class _ListStepIterator<E> implements Iterator<E> {
  _InternalLinkedHashMap _map;
  Object _modMark;
  List _list;
  int _offset;
  int _step;

  _ListStepIterator(this._map, this._modMark,
                    this._list, this._offset, this._step);

  bool moveNext() {
    if (_map._getModMark(false) != _modMark) {
      throw new ConcurrentModificationError(_map);
    }
    _offset += _step;
    return _offset < _list.length;
  }

  E get current {
    if (_offset < 0 || _offset >= _list.length) {
      return null;
    }
    return _list[_offset];
  }
}

