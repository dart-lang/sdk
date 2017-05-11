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
 * The elements of a `LinkedHashSet` must have consistent [Object.==]
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
   * methods won't work on all objects, but only on some instances of E, the
   * [isValidKey] predicate can be used to restrict the keys that the functions
   * are applied to.
   * Any key for which [isValidKey] returns false is automatically assumed
   * to not be in the set when asking `contains`.
   *
   * If [equals] or [hashCode] are omitted, the set uses
   * the elements' intrinsic [Object.==] and [Object.hashCode],
   * and [isValidKey] is ignored since these operations are assumed
   * to work on all objects.
   *
   * If you supply one of [equals] and [hashCode],
   * you should generally also to supply the other.
   *
   * If the supplied `equals` or `hashCode` functions won't work on all [E]
   * objects, and the map will be used in a setting where a non-`E` object
   * is passed to, e.g., `contains`, then the [isValidKey] function should
   * also be supplied.
   *
   * If [isValidKey] is omitted, it defaults to testing if the object is an
   * [E] instance. That means that:
   *
   *     new LinkedHashSet<int>(equals: (int e1, int e2) => (e1 - e2) % 5 == 0,
   *                            hashCode: (int e) => e % 5)
   *
   * does not need an `isValidKey` argument, because it defaults to only
   * accepting `int` values which are accepted by both `equals` and `hashCode`.
   *
   * If neither `equals`, `hashCode`, nor `isValidKey` is provided,
   * the default `isValidKey` instead accepts all values.
   * The default equality and hashcode operations are assumed to work on all
   * objects.
   *
   * Likewise, if `equals` is [identical], `hashCode` is [identityHashCode]
   * and `isValidKey` is omitted, the resulting set is identity based,
   * and the `isValidKey` defaults to accepting all keys.
   * Such a map can be created directly using [LinkedHashSet.identity].
   */
  external factory LinkedHashSet(
      {bool equals(E e1, E e2),
      int hashCode(E e),
      bool isValidKey(potentialKey)});

  /**
   * Creates an insertion-ordered identity-based set.
   *
   * Effectively a shorthand for:
   *
   *     new LinkedHashSet<E>(equals: identical,
   *                          hashCode: identityHashCode)
   */
  external factory LinkedHashSet.identity();

  /**
   * Create a linked hash set containing all [elements].
   *
   * Creates a linked hash set as by `new LinkedHashSet<E>()` and adds each
   * element of `elements` to this set in the order they are iterated.
   *
   * All the [elements] should be assignable to [E].
   * The `elements` iterable itself may have any element type,
   * so this constructor can be used to down-cast a `Set`, for example as:
   *
   *     Set<SuperType> superSet = ...;
   *     Iterable<SuperType> tmp = superSet.where((e) => e is SubType);
   *     Set<SubType> subSet = new LinkedHashSet<SubType>.from(tmp);
   */
  factory LinkedHashSet.from(Iterable elements) {
    LinkedHashSet<E> result = new LinkedHashSet<E>();
    for (final element in elements) {
      E e = element as Object/*=E*/;
      result.add(e);
    }
    return result;
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
