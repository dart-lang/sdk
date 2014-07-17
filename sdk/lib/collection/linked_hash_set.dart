// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * A [LinkedHashSet] is a hash-table based [Set] implementation.
 *
 * The `LinkedHashSet` also keep track of the order that elements were inserted
 * in, and iteration happens in first-to-last insertion order.
 *
 * The elements of a `LinkedHashSet` must have consistent [Object.operator==]
 * and [Object.hashCode] implementations. This means that the `==` operator
 * must define a stable equivalence relation on the elements (reflexive,
 * symmetric, transitive, and consistent over time), and that `hashCode`
 * must be the same for objects that are considered equal by `==`.
 *
 * The set allows `null` as an element.
 *
 * Iteration of elements is done in element insertion order.
 * An element that was added after another will occur later in the iteration.
 * Adding an element that is already in the set
 * does not change its position in the iteration order,
 * but removing an element and adding it again,
 * will make it the last element of an iteration.
 *
 * Most simple operations on `HashSet` are done in (potentially amortized)
 * constant time: [add], [contains], [remove], and [length], provided the hash
 * codes of objects are well distributed..
 */
abstract class LinkedHashSet<E> implements HashSet<E> {
  /**
   * Create an insertion-ordered hash set using the provided
   * [equals] and [hashCode].
   *
   * The provided [equals] must define a stable equivalence relation, and
   * [hashCode] must be consistent with [equals]. If the [equals] or [hashCode]
   * methods won't work on all objects, but only to instances of E, the
   * [isValidKey] predicate can be used to restrict the keys that they are
   * applied to. Any key for which [isValidKey] returns false is automatically
   * assumed to not be in the set.
   *
   * If [equals] or [hashCode] are omitted, the set uses
   * the objects' intrinsic [Object.operator==] and [Object.hashCode],
   *
   * If [isValidKey] is omitted, it defaults to testing if the object is an
   * [E] instance.
   *
   * If you supply one of [equals] and [hashCode],
   * you should generally also to supply the other.
   * An example would be using [identical] and [identityHashCode],
   * which is equivalent to using the shorthand [LinkedSet.identity]).
   */
  external factory LinkedHashSet({ bool equals(E e1, E e2),
                                   int hashCode(E e),
                                   bool isValidKey(potentialKey) });

  /**
   * Creates an insertion-ordered identity-based set.
   *
   * Effectively a shorthand for:
   *
   *     new LinkedHashSet(equals: identical, hashCode: identityHashCodeOf)
   */
  external factory LinkedHashSet.identity();

  factory LinkedHashSet.from(Iterable<E> iterable) {
    return new LinkedHashSet<E>()..addAll(iterable);
  }

  /**
   * Executes a function on each element of the set.
   *
   * The elements are iterated in insertion order.
   */
  void forEach(void action(E element));

  /**
   * Provides an iterator that iterates over the elements in insertion order.
   */
  Iterator<E> get iterator;
}
