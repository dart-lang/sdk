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
 * anti-symmetric, transitive, and consistent over time), and that `hashCode`
 * must be the same for objects that are considered equal by `==`.
 *
 * The set allows `null` as an element.
 *
 * Most simple operations on `HashSet` are done in (potentially amortized)
 * constant time: [add], [contains], [remove], and [length], provided the hash
 * codes of objects are well distributed..
 */
abstract class LinkedHashSet<E> implements HashSet<E> {

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
}
