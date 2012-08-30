// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This class is the public interface of a set. A set is a collection
 * without duplicates.
 */
interface Set<E> extends Collection<E>
    default HashSetImplementation<E extends Hashable> {
  Set();

  /**
   * Creates a [Set] that contains all elements of [other].
   */
  Set.from(Iterable<E> other);

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

interface HashSet<E extends Hashable> extends Set<E>
    default HashSetImplementation<E extends Hashable> {
  HashSet();

  /**
   * Creates a [Set] that contains all elements of [other].
   */
  HashSet.from(Iterable<E> other);
}
