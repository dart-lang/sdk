// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;



class HashSet<E> extends Collection<E> implements Set<E> {
  // The map backing this set. The associations in this map are all
  // of the form element -> element. If a value is not in the map,
  // then it is not in the set.
  final _HashMapImpl<E, E> _backingMap;

  HashSet() : _backingMap = new _HashMapImpl<E, E>();

  /**
   * Creates a [Set] that contains all elements of [other].
   */
  factory HashSet.from(Iterable<E> other) {
    Set<E> set = new HashSet<E>();
    for (final e in other) {
      set.add(e);
    }
    return set;
  }

  void clear() {
    _backingMap.clear();
  }

  void add(E value) {
    _backingMap[value] = value;
  }

  bool remove(Object value) {
    if (!_backingMap.containsKey(value)) return false;
    _backingMap.remove(value);
    return true;
  }

  bool contains(E value) {
    return _backingMap.containsKey(value);
  }

  Set<E> intersection(Collection<E> collection) {
    Set<E> result = new Set<E>();
    collection.forEach((E value) {
      if (contains(value)) result.add(value);
    });
    return result;
  }

  bool isSubsetOf(Collection<E> other) {
    return new Set<E>.from(other).containsAll(this);
  }

  bool containsAll(Collection<E> collection) {
    return collection.every((E value) {
      return contains(value);
    });
  }

  void forEach(void f(E element)) {
    _backingMap.forEach((E key, E value) {
      f(key);
    });
  }

  bool get isEmpty {
    return _backingMap.isEmpty;
  }

  int get length {
    return _backingMap.length;
  }

  Iterator<E> get iterator => new _HashSetIterator<E>(this);

  String toString() {
    return Collections.collectionToString(this);
  }
}

class _HashSetIterator<E> implements Iterator<E> {

  _HashSetIterator(HashSet<E> set)
    : _keysIterator = set._backingMap._keys.iterator;

  E get current {
    var result = _keysIterator.current;
    if (identical(result, _HashMapImpl._DELETED_KEY)) {
      // TODO(floitsch): improve the error reporting.
      throw new StateError("Concurrent modification.");
    }
    return result;
  }

  bool moveNext() {
    bool result;
    do {
      result = _keysIterator.moveNext();
    } while (result &&
             (_keysIterator.current == null ||
              identical(_keysIterator.current, _HashMapImpl._DELETED_KEY)));
    return result;
  }

  Iterator _keysIterator;
}
