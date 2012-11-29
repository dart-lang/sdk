// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_core;

/**
 * The common interface of all collections.
 *
 * The [Collection] class contains a skeleton implementation of
 * an iterator based collection.
 */
abstract class Collection<E> extends Iterable<E> {
  /**
   * Returns a new collection with the elements [: f(e) :]
   * for each element [:e:] of this collection.
   *
   * Subclasses of [Collection] should implement the [map] method
   * to return a collection of the same general type as themselves.
   * E.g., [List.map] should return a [List].
   */
  Collection map(f(E element));

  /**
   * Returns a collection with the elements of this collection
   * that satisfy the predicate [f].
   *
   * The returned collection should be of the same type as the collection
   * creating it.
   *
   * An element satisfies the predicate [f] if [:f(element):]
   * returns true.
   */
  Collection<E> filter(bool f(E element));

  /**
   * Returns the number of elements in this collection.
   */
  int get length;

  /**
   * Check whether the collection contains an element equal to [element].
   */
  bool contains(E element) {
    for (E e in this) {
      if (e == element) return true;
    }
    return false;
  }

  /**
   * Applies the function [f] to each element of this collection.
   */
  void forEach(void f(E element)) {
    for (E element in this) f(element);
  }

  /**
   * Reduce a collection to a single value by iteratively combining each element
   * of the collection with an existing value using the provided function.
   * Use [initialValue] as the initial value, and the function [combine] to
   * create a new value from the previous one and an element.
   *
   * Example of calculating the sum of a collection:
   *
   *   collection.reduce(0, (prev, element) => prev + element);
   */
  dynamic reduce(var initialValue,
                 dynamic combine(var previousValue, E element)) {
    var value = initialValue;
    for (E element in this) value = combine(value, element);
    return value;
  }

  /**
   * Returns true if every elements of this collection satisify the
   * predicate [f]. Returns false otherwise.
   */
  bool every(bool f(E element)) {
    for (E element in this) {
      if (!f(element)) return false;
    }
    return true;
  }

  /**
   * Returns true if one element of this collection satisfies the
   * predicate [f]. Returns false otherwise.
   */
  bool some(bool f(E element)) {
    for (E element in this) {
      if (f(element)) return true;
    }
    return false;
  }

  /**
   * Returns true if there is no element in this collection.
   */
  bool get isEmpty => !iterator().hasNext;
}
