// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * This class is the public interface of a set. A set is a collection
 * without duplicates.
 */
abstract class Set<E> extends Collection<E> {
  factory Set() => new HashSet<E>();

  /**
   * Creates a [Set] that contains all elements of [other].
   */
  factory Set.from(Iterable<E> other) => new HashSet<E>.from(other);

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
  bool remove(Object value);

  /**
   * Returns true if [other] contains all the elements of this Set.
   *
   * *Deprecated*. Use `other.containsAll(thisSet)` instead if [other]
   * is a Set, and convert `other` to a Set if it isn't.
   */
  @deprecated
  bool isSubsetOf(Iterable<E> other);

  /**
   * Returns true if this Set contains all the elements of [other].
   */
  bool containsAll(Iterable<E> other);

  /**
   * Returns a new set which is the intersection between this set and [other].
   */
  Set<E> intersection(Set<E> other);

  /**
   * Returns a new set which contains all the elements of this set and [other].
   */
  Set<E> union(Set<E> other);

  /**
   * Returns a new set with the the elements of this that are not in [other].
   */
  Set<E> difference(Set<E> other);

  /**
   * Removes all elements in the set.
   */
  void clear();
}
