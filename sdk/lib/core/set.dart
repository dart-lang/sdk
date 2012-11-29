// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_core;

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
   * Adds all the elements of the given collection to the set.
   */
  void addAll(Collection<E> collection);

  /**
   * Removes all the elements of the given collection from the set.
   */
  void removeAll(Collection<E> collection);

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


class _HashSetImpl<E> implements HashSet<E> {

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

  void addAll(Collection<E> collection) {
    collection.forEach((E value) {
      add(value);
    });
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

  void removeAll(Collection<E> collection) {
    collection.forEach((E value) {
      remove(value);
    });
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

  Set map(f(E element)) {
    Set result = new Set();
    _backingMap.forEach((E key, E value) {
      result.add(f(key));
    });
    return result;
  }

  dynamic reduce(dynamic initialValue,
                 dynamic combine(dynamic previousValue, E element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  Set<E> filter(bool f(E element)) {
    Set<E> result = new Set<E>();
    _backingMap.forEach((E key, E value) {
      if (f(key)) result.add(key);
    });
    return result;
  }

  bool every(bool f(E element)) {
    Collection<E> keys = _backingMap.keys;
    return keys.every(f);
  }

  bool some(bool f(E element)) {
    Collection<E> keys = _backingMap.keys;
    return keys.some(f);
  }

  bool get isEmpty {
    return _backingMap.isEmpty;
  }

  int get length {
    return _backingMap.length;
  }

  Iterator<E> iterator() {
    return new _HashSetIterator<E>(this);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  // The map backing this set. The associations in this map are all
  // of the form element -> element. If a value is not in the map,
  // then it is not in the set.
  _HashMapImpl<E, E> _backingMap;
}

class _HashSetIterator<E> implements Iterator<E> {

  // TODO(4504458): Replace set_ with set.
  _HashSetIterator(_HashSetImpl<E> set_)
    : _nextValidIndex = -1,
      _entries = set_._backingMap._keys {
    _advance();
  }

  bool get hasNext {
    if (_nextValidIndex >= _entries.length) return false;
    if (identical(_entries[_nextValidIndex], _HashMapImpl._DELETED_KEY)) {
      // This happens in case the set was modified in the meantime.
      // A modification on the set may make this iterator misbehave,
      // but we should never return the sentinel.
      _advance();
    }
    return _nextValidIndex < _entries.length;
  }

  E next() {
    if (!hasNext) {
      throw new StateError("No more elements");
    }
    E res = _entries[_nextValidIndex];
    _advance();
    return res;
  }

  void _advance() {
    int length = _entries.length;
    var entry;
    final deletedKey = _HashMapImpl._DELETED_KEY;
    do {
      if (++_nextValidIndex >= length) break;
      entry = _entries[_nextValidIndex];
    } while ((entry == null) || identical(entry, deletedKey));
  }

  // The entries in the set. May contain null or the sentinel value.
  List<E> _entries;

  // The next valid index in [_entries] or the length of [entries_].
  // If it is the length of [_entries], calling [hasNext] on the
  // iterator will return false.
  int _nextValidIndex;
}
