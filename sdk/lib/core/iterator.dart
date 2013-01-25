// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The [Iterator] class provides methods to iterate over an object. It
 * is transparently used by the for-in construct to test for the end
 * of the iteration, and to get the elements.
 *
 * If the object iterated over is changed during the iteration, the
 * behavior is unspecified.
 *
 * The [Iterator] is initially positioned before the first element. Before
 * accessing the first element the iterator must thus be advanced ([moveNext])
 * to point to the first element. If there is no element left, then [moveNext]
 * returns false.
 *
 * A typical usage of an [Iterator] looks as follows:
 *
 *     var it = obj.iterator;
 *     while (it.moveNext()) {
 *       use(it.current);
 *     }
 */
abstract class Iterator<E> {
  /**
   * Moves to the next element. Returns true if [current] contains the next
   * element. Returns false, if no element was left.
   *
   * It is safe to invoke [moveNext] even when the iterator is already
   * positioned after the last element. In this case [moveNext] has no effect.
   */
  bool moveNext();

  /**
   * Returns the current element.
   *
   * Return [:null:] if the iterator has not yet been moved to the first
   * element, or if the iterator has been moved after the last element of the
   * [Iterable].
   */
  E get current;
}
