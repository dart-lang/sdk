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
 * Most simple operations on `HashSet` are done in (potentially amorteized)
 * constant time: [add], [contains], [remove], and [length], provided the hash
 * codes of objects are well distributed.
 */
abstract class HashSet<E> implements Set<E> {
  @patch
  factory HashSet({ bool equals(E e1, E e2),
                    int hashCode(E e),
                    bool isValidKey(potentialKey) }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _HashSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _IdentityHashSet<E>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return new _CustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @patch
  factory HashSet.identity() = _IdentityHashSet<E>;

  /**
   * Create a hash set containing all [elements].
   *
   * Creates a hash set as by `new HashSet<E>()` and adds each element of
   * `elements` to this set in the order they are iterated.
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
    for (E e in elements) result.add(e);
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
