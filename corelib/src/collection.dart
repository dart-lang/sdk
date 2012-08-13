// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The [Collection] interface is the public interface of all
 * collections.
 */
interface Collection<E> extends Iterable<E> {
  /**
   * Applies the function [f] to each element of this collection.
   */
  void forEach(void f(E element));

  /**
   * Returns a new collection with the elements [: f(e) :]
   * for each element [:e:] of this collection.
   *
   * Note on typing: the return type of f() could be an arbitrary
   * type and consequently the returned collection's
   * typeis Collection.
   */
  Collection map(f(E element));

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
  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic previousValue, E element));

  /**
   * Returns a new collection with the elements of this collection
   * that satisfy the predicate [f].
   *
   * An element satisfies the predicate [f] if [:f(element):]
   * returns true.
   */
  Collection<E> filter(bool f(E element));

  /**
   * Returns true if every elements of this collection satisify the
   * predicate [f]. Returns false otherwise.
   */
  bool every(bool f(E element));

  /**
   * Returns true if one element of this collection satisfies the
   * predicate [f]. Returns false otherwise.
   */
  bool some(bool f(E element));

  /**
   * Returns true if there is no element in this collection.
   */
  bool isEmpty();

  /**
   * Returns the number of elements in this collection.
   */
  int get length();
}
