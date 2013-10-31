// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/** Common parts of [HashSet] and [LinkedHashSet] implementations. */
abstract class _HashSetBase<E> extends IterableBase<E> implements Set<E> {

  // Set.
  bool containsAll(Iterable<Object> other) {
    for (Object object in other) {
      if (!this.contains(object)) return false;
    }
    return true;
  }

  /** Create a new Set of the same type as this. */
  HashSet<E> _newSet();

  Set<E> intersection(Set<Object> other) {
    Set<E> result = _newSet();
    if (other.length < this.length) {
      for (var element in other) {
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

  void _retainAll(Iterable objectsToRetain, bool isValidKey(Object o)) {
    // TODO(lrn): Consider optimizing table based versions by
    // building a new table of the entries to retain.
    Set retainSet = _newSet();
    for (Object o in objectsToRetain) {
      if (isValidKey(o)) {
        retainSet.add(o);
      }
    }
    retainWhere(retainSet.contains);
  }

  List<E> toList({bool growable: true}) {
    List<E> result = growable ? (new List<E>()..length = this.length)
                              : new List<E>(this.length);
    int i = 0;
    for (E element in this) result[i++] = element;
    return result;
  }

  Set<E> toSet() => _newSet()..addAll(this);

  String toString() => IterableMixinWorkaround.toStringIterable(this, '{', '}');
}

/**
 * A [HashSet] is a hash-table based [Set] implementation.
 *
 * The elements of a `HashSet` must have consistent equality
 * and hashCode implementations. This means that the equals operation
 * must define a stable equivalence relation on the elements (reflexive,
 * anti-symmetric, transitive, and consistent over time), and that the hashCode
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
  /**
   * Create a hash set using the provided [equals] as equality.
   *
   * The provided [equals] must define a stable equivalence relation, and
   * [hashCode] must be consistent with [equals]. If the [equals] or [hashCode]
   * methods won't work on all objects, but only to instances of E, the
   * [isValidKey] predicate can be used to restrict the keys that they are
   * applied to. Any key for which [isValidKey] returns false is automatically
   * assumed to not be in the set.
   *
   * If [equals], [hashCode] and [isValidKey] are omitted, the set uses
   * the objects' intrinsic [Object.operator==] and [Object.hashCode].
   *
   * If [isValidKey] is omitted, it defaults to testing if the object is an
   * [E] instance.
   *
   * If [equals] is [identical], this creates an identity set. Any hashCode
   * is compatible with [identical], and it applies to all objects, so
   * [hashCode] and [isValidKey] can safely be omitted.
   */
  external factory HashSet({ bool equals(E e1, E e2),
                             int hashCode(E e),
                             bool isValidKey(potentialKey) });

  /**
   * Creates an unordered identity-based set.
   *
   * Effectively a shorthand for:
   *
   *     new HashSet(equals: identical, hashCode: identityHashCodeOf)
   */
  external factory HashSet.identity();

  /**
   * Create a hash set containing the elements of [iterable].
   *
   * Creates a hash set as by `new HashSet<E>()` and adds each element of
   * `iterable` to this set in the order they are iterated.
   */
  factory HashSet.from(Iterable<E> iterable) {
    return new HashSet<E>()..addAll(iterable);
  }
}
