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
 * Most simple operations on `HashSet` are done in constant time: [add],
 * [contains], [remove], and [length].
 */
class LinkedHashSet<E> extends _HashSetBase<E> {

  external LinkedHashSet();

  factory LinkedHashSet.from(Iterable<E> iterable) {
    return new LinkedHashSet<E>()..addAll(iterable);
  }

  // Iterable.

  /** Return an iterator that iterates over elements in insertion order. */
  external Iterator<E> get iterator;

  external int get length;

  external bool get isEmpty;

  external bool get isNotEmpty;

  external bool contains(Object object);

  /** Perform an operation on each element in insertion order. */
  external void forEach(void action(E element));

  external E get first;

  external E get last;

  E get single {
    if (length == 1) return first;
    var message = (length == 0) ? "No Elements" : "Too many elements";
    throw new StateError(message);
  }

  // Collection.
  external void add(E element);

  external void addAll(Iterable<E> objects);

  external bool remove(Object object);

  external void removeAll(Iterable objectsToRemove);

  external void removeWhere(bool test(E element));

  external void retainWhere(bool test(E element));

  external void clear();

  // Set.
  Set<E> _newSet() => new LinkedHashSet<E>();
}
