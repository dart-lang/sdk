// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/** Common parts of [HashSet] and [LinkedHashSet] implementations. */
abstract class _HashSetBase<E> extends SetBase<E> {
  // The following two methods override the ones in SetBase.
  // It's possible to be more efficient if we have a way to create an empty
  // set of the correct type.

  Set<E> difference(Set<Object> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> intersection(Set<Object> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> _newSet();

  // Subclasses can optimize this further.
  Set<E> toSet() => _newSet()..addAll(this);
}

/**
 * An unordered hash-table based [Set] implementation.
 *
 * The elements of a `HashSet` must have consistent equality
 * and hashCode implementations. This means that the equals operation
 * must define a stable equivalence relation on the elements (reflexive,
 * symmetric, transitive, and consistent over time), and that the hashCode
 * must consistent with equality, so that the same for objects that are
 * considered equal.
 *
 * The set allows `null` as an element.
 *
 * Most simple operations on `HashSet` are done in (potentially amortized)
 * constant time: [add], [contains], [remove], and [length], provided the hash
 * codes of objects are well distributed.
 *
 * The iteration order of the set is not specified and depends on
 * the hashcodes of the provided elements. However, the order is stable:
 * multiple iterations over the same set produce the same order, as long as
 * the set is not modified.
 */
abstract class HashSet<E> implements Set<E> {
  /**
   * Create a hash set using the provided [equals] as equality.
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
   * the elements' intrinsic [Object.==] and [Object.hashCode].
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
   *     new HashSet<int>(equals: (int e1, int e2) => (e1 - e2) % 5 == 0,
   *                      hashCode: (int e) => e % 5)
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
   * Such a map can be created directly using [HashSet.identity].
   */
  external factory HashSet(
      {bool equals(E e1, E e2),
      int hashCode(E e),
      bool isValidKey(potentialKey)});

  /**
   * Creates an unordered identity-based set.
   *
   * Effectively a shorthand for:
   *
   *     new HashSet<E>(equals: identical,
   *                    hashCode: identityHashCode)
   */
  external factory HashSet.identity();

  /**
   * Create a hash set containing all [elements].
   *
   * Creates a hash set as by `new HashSet<E>()` and adds all given [elements]
   * to the set. The elements are added in order. If [elements] contains
   * two entries that are equal, but not identical, then the first one is
   * the one in the resulting set.
   *
   * All the [elements] should be assignable to [E].
   * The `elements` iterable itself may have any element type, so this
   * constructor can be used to down-cast a `Set`, for example as:
   *
   *     Set<SuperType> superSet = ...;
   *     Set<SubType> subSet =
   *         new HashSet<SubType>.from(superSet.where((e) => e is SubType));
   */
  factory HashSet.from(Iterable elements) {
    HashSet<E> result = new HashSet<E>();
    for (final e in elements) {
      result.add(e);
    }
    return result;
  }

  /**
   * Provides an iterator that iterates over the elements of this set.
   *
   * The order of iteration is unspecified,
   * but consistent between changes to the set.
   */
  Iterator<E> get iterator;
}
