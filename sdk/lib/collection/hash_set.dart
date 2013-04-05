// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class HashSet<E> extends Collection<E> implements Set<E> {
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

  void retainAll(Iterable objectsToRetain) {
    IterableMixinWorkaround.retainAll(this, objectsToRetain);
  }

  external void removeWhere(bool test(E element));

  external void retainWhere(bool test(E element));

  external void clear();

  // Set.
  bool isSubsetOf(Collection<E> other) {
    // Deprecated, and using old signature.
    Set otherSet;
    if (other is Set) {
      otherSet = other;
    } else {
      otherSet = other.toSet();
    }
    return IterableMixinWorkaround.setContainsAll(otherSet, this);
  }

  bool containsAll(Iterable<E> other) {
    return IterableMixinWorkaround.setContainsAll(this, other);
  }

  Set<E> intersection(Set<E> other) {
    return IterableMixinWorkaround.setIntersection(
        this, other, new HashSet<E>());
  }

  Set<E> union(Set<E> other) {
    return IterableMixinWorkaround.setUnion(this, other, new HashSet<E>());
  }

  Set<E> difference(Set<E> other) {
    return IterableMixinWorkaround.setDifference(this, other, new HashSet<E>());
  }

  String toString() => Collections.collectionToString(this);
}
