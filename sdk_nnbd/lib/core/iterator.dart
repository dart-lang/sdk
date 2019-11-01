// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An interface for getting items, one at a time, from an object.
 *
 * The for-in construct transparently uses `Iterator` to test for the end
 * of the iteration, and to get each item (or _element_).
 *
 * If the object iterated over is changed during the iteration, the
 * behavior is unspecified.
 *
 * The `Iterator` is initially positioned before the first element.
 * Before accessing the first element the iterator must thus be advanced using
 * [moveNext] to point to the first element.
 * If no element is left, then [moveNext] returns false,
 * and all further calls to [moveNext] will also return false.
 *
 * The [current] value must not be accessed before calling [moveNext]
 * or after a call to [moveNext] has returned false.
 *
 * A typical usage of an Iterator looks as follows:
 *
 *     var it = obj.iterator;
 *     while (it.moveNext()) {
 *       use(it.current);
 *     }
 *
 * **See also:**
 * [Iteration](http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html#iteration)
 * in the [library tour](http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html)
 */
abstract class Iterator<E> {
  /**
   * Moves to the next element.
   *
   * Returns true when [current] can be used to access the next element.
   * Returns false if no elements are left.
   *
   * It is safe to invoke [moveNext] even when the iterator is already
   * positioned after the last element.
   * In this case [moveNext] returns false again and has no effect.
   *
   * A call to [moveNext] may throw if iteration has been broken by
   * changing the underlying collection, or for other reasons specific to
   * a particular iterator.
   * The iterator should not be used after [moveNext] throws.
   * If it is used, the value of [current] and the behavior of
   * calling [moveNext] again are unspecified.
   */
  bool moveNext();

  /**
   * Returns the current element.
   *
   * If the iterator has not yet been moved to the first element
   * ([moveNext] has not been called yet),
   * or if the iterator has been moved past the last element of the [Iterable]
   * ([moveNext] has returned false),
   * then [current] is unspecified.
   * An [Iterator] may either throw or return an iterator specific default value
   * in that case.
   *
   * The `current` getter should keep its value until the next call to
   * [moveNext], even if an underlying collection changes.
   * After a successful call to `moveNext`, the user doesn't need to cache
   * the current value, but can keep reading it from the iterator.
   */
  E get current;
}
