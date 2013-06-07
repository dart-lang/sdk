// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A `Set` is a collection of elements where each element can occur only once.
 *
 * That is, for each object of the element type, the object is either considered
 * to be in the set, or it is not in the set.
 *
 * Set implementations may consider some elements indistinguishable. These
 * objects will be treated as being the same for any operation on the set.
 *
 * The default `Set` implementation, [HashSet], considers objects
 * indistinguishable if they are equal with regard to [Object.operator==].
 *
 * Sets may be either ordered or unordered. [HashSet] is unordered and doesn't
 * guarantee anything about the order that elements are accessed in by
 * iteration. [LinkedHashSet] iterates in the insertion order of its elements.
 */
abstract class Set<E> extends IterableBase<E> {
  /**
   * Creates an empty [Set].
   *
   * The created `Set` is a [HashSet]. As such, it considers elements that
   * are equal (using `==`) to be undistinguishable, and requires them to
   * have a compatible [Object.hashCode] implementation.
   */
  factory Set() => new HashSet<E>();

  /**
   * Creates a [Set] that contains all elements of [other].
   *
   * The created `Set` is a [HashSet]. As such, it considers elements that
   * are equal (using `==`) to be undistinguishable, and requires them to
   * have a compatible [Object.hashCode] implementation.
   */
  factory Set.from(Iterable<E> other) => new HashSet<E>.from(other);

  /**
   * Returns true if [value] is in the set.
   */
  bool contains(E value);

  /**
   * Adds [value] into the set.
   *
   * The method has no effect if [value] is already in the set.
   */
  void add(E value);

  /**
   * Adds all of [elements] to this Set.
   *
   * Equivalent to adding each element in [elements] using [add],
   * but some collections may be able to optimize it.
   */
  void addAll(Iterable<E> elements);

  /**
   * Removes [value] from the set. Returns true if [value] was
   * in the set. Returns false otherwise. The method has no effect
   * if [value] value was not in the set.
   */
  bool remove(Object value);

  /**
   * Removes each element of [elements] from this set.
   */
  void removeAll(Iterable elements);

  /**
   * Removes all elements of this set that are not elements in [elements].
   */
  void retainAll(Iterable elements);

  /**
   * Removes all elements of this set that satisfy [test].
   */
  void removeWhere(bool test(E element));

  /**
   * Removes all elements of this set that fail to satisfy [test].
   */
  void retainWhere(bool test(E element));

  /**
   * Returns whether this Set contains all the elements of [other].
   */
  bool containsAll(Iterable<E> other);

  /**
   * Returns a new set which is the intersection between this set and [other].
   *
   * That is, the returned set contains all the elements of this `Set` that
   * are also elements of [other].
   */
  Set<E> intersection(Set<E> other);

  /**
   * Returns a new set which contains all the elements of this set and [other].
   *
   * That is, the returned set contains all the elements of this `Set` and
   * all the elements of [other].
   */
  Set<E> union(Set<E> other);

  /**
   * Returns a new set with the the elements of this that are not in [other].
   *
   * That is, the returned set contains all the elements of this `Set` that
   * are not elements of [other].
   */
  Set<E> difference(Set<E> other);

  /**
   * Removes all elements in the set.
   */
  void clear();
}
