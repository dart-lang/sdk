// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/** Common parts of [HashSet] and [LinkedHashSet] implementations. */
abstract class _HashSetBase<E> extends IterableBase<E> implements Set<E> {
  // Set.
  bool containsAll(Iterable<E> other) {
    for (E object in other) {
      if (!this.contains(object)) return false;
    }
    return true;
  }

  /** Create a new Set of the same type as this. */
  Set _newSet();

  Set<E> intersection(Set<E> other) {
    Set<E> result = _newSet();
    if (other.length < this.length) {
      for (E element in other) {
        if (this.contains(element)) result.add(element);
      }
    } else {
      for (E element in this) {
        if (other.contains(element)) result.add(element);
      }
    }
    return result;
  }

  Set<E> union(Set<E> other) {
    return _newSet()..addAll(this)..addAll(other);
  }

  Set<E> difference(Set<E> other) {
    HashSet<E> result = _newSet();
    for (E element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  void retainAll(Iterable objectsToRetain) {
    Set retainSet;
    if (objectsToRetain is Set) {
      retainSet = objectsToRetain;
    } else {
      retainSet = objectsToRetain.toSet();
    }
    retainWhere(retainSet.contains);
  }

  String toString() => ToString.iterableToString(this);
}

class HashSet<E> extends _HashSetBase<E> {
  external HashSet();

  factory HashSet.from(Iterable<E> iterable) {
    return new HashSet<E>()..addAll(iterable);
  }

  // Iterable.
  external Iterator<E> get iterator;

  external int get length;

  external bool get isEmpty;

  external bool contains(Object object);

  // Collection.
  external void add(E element);

  external void addAll(Iterable<E> objects);

  external bool remove(Object object);

  external void removeAll(Iterable objectsToRemove);

  external void removeWhere(bool test(E element));

  external void retainWhere(bool test(E element));

  external void clear();

  // Set.
  Set<E> _newSet() => new HashSet<E>();
}
