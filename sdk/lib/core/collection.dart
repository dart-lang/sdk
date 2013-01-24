// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A collection of individual elements.
 *
 * A [Collection] contains some elements in a structure optimized
 * for certain operations. Different collections are optimized for different
 * uses.
 *
 * A collection can be updated by adding or removing elements.
 *
 * Collections are [Iterable]. The order of iteration is defined by
 * each type of collection.
 */
abstract class Collection<E> extends Iterable<E> {
  const Collection();

  /**
   * Adds an element to this collection.
   */
  void add(E element);

  /**
   * Adds all of [elements] to this collection.
   *
   * Equivalent to adding each element in [elements] using [add],
   * but some collections may be able to optimize it.
   */
  void addAll(Iterable<E> elements) {
    for (E element in elements) {
      add(element);
    }
  }

  /**
   * Removes an instance of [element] from this collection.
   *
   * This removes only one instance of the element for collections that can
   * contain the same element more than once (e.g., [List]). Which instance
   * is removed is decided by the collection.
   *
   * Has no effect if the elements is not in this collection.
   */
  void remove(Object element);

  /**
   * Removes all of [elements] from this collection.
   *
   * Equivalent to calling [remove] once for each element in
   * [elements], but may be faster for some collections.
   */
  void removeAll(Iterable elements) {
    IterableMixinWorkaround.removeAll(this, elements);
  }

  /**
   * Removes all elements of this collection that are not
   * in [elements].
   *
   * For [Set]s, this is the intersection of the two original sets.
   */
  void retainAll(Iterable elements) {
    IterableMixinWorkaround.retainAll(this, elements);
  }

  /**
   * Removes all elements of this collection that satisfy [test].
   *
   * An elements [:e:] satisfies [test] if [:test(e):] is true.
   */
  void removeMatching(bool test(E element)) {
    IterableMixinWorkaround.removeMatching(this, test);
  }

  /**
   * Removes all elements of this collection that fail to satisfy [test].
   *
   * An elements [:e:] satisfies [test] if [:test(e):] is true.
   */
  void retainMatching(bool test(E element)) {
    IterableMixinWorkaround.retainMatching(this, test);
  }

  /**
   * Removes all elements of this collection.
   */
  void clear() {
    IterableMixinWorkaround.removeMatching(this, (E e) => true);
  }
}
