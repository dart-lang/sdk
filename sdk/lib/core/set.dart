// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * This class is the public interface of a set. A set is a collection
 * without duplicates.
 */
abstract class Set<E> extends Collection<E> {
  factory Set() => new _HashSetImpl<E>();

  /**
   * Creates a [Set] that contains all elements of [other].
   */
  factory Set.from(Iterable<E> other) => new _HashSetImpl<E>.from(other);

  /**
   * Returns true if [value] is in the set.
   */
  bool contains(E value);

  /**
   * Adds [value] into the set. The method has no effect if
   * [value] was already in the set.
   */
  void add(E value);

  /**
   * Removes [value] from the set. Returns true if [value] was
   * in the set. Returns false otherwise. The method has no effect
   * if [value] value was not in the set.
   */
  bool remove(E value);

  /**
   * Adds all the elements of the given [iterable] to the set.
   */
  void addAll(Iterable<E> iterable);

  /**
   * Removes all the elements of the given collection from the set.
   */
  void removeAll(Iterable<E> iterable);

  /**
   * Returns true if [collection] contains all the elements of this
   * collection.
   */
  bool isSubsetOf(Collection<E> collection);

  /**
   * Returns true if this collection contains all the elements of
   * [collection].
   */
  bool containsAll(Collection<E> collection);

  /**
   * Returns a new set which is the intersection between this set and
   * the given collection.
   */
  Set<E> intersection(Collection<E> other);

  /**
   * Removes all elements in the set.
   */
  void clear();

}

abstract class HashSet<E> extends Set<E> {
  factory HashSet() => new _HashSetImpl<E>();

  /**
   * Creates a [Set] that contains all elements of [other].
   */
  factory HashSet.from(Iterable<E> other) => new _HashSetImpl<E>.from(other);
}


class _HashSetImpl<E> extends Iterable<E> implements HashSet<E> {

  _HashSetImpl() {
    _backingMap = new _HashMapImpl<E, E>();
  }

  factory _HashSetImpl.from(Iterable<E> other) {
    Set<E> set = new _HashSetImpl<E>();
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

  bool contains(E value) {
    return _backingMap.containsKey(value);
  }

  bool remove(E value) {
    if (!_backingMap.containsKey(value)) return false;
    _backingMap.remove(value);
    return true;
  }

  void addAll(Iterable<E> iterable) {
    for (E element in iterable) {
      add(element);
    }
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

  void removeAll(Iterable<E> iterable) {
    for (E value in iterable) {
      remove(value);
    }
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

  // The map backing this set. The associations in this map are all
  // of the form element -> element. If a value is not in the map,
  // then it is not in the set.
  _HashMapImpl<E, E> _backingMap;
}

class _HashSetIterator<E> implements Iterator<E> {

  _HashSetIterator(_HashSetImpl<E> set)
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
