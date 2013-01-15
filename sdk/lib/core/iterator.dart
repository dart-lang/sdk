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

class HasNextIterator<E> {
  static const int _HAS_NEXT_AND_NEXT_IN_CURRENT = 0;
  static const int _NO_NEXT = 1;
  static const int _NOT_MOVED_YET = 2;

  Iterator _iterator;
  int _state = _NOT_MOVED_YET;

  HasNextIterator(this._iterator);

  bool get hasNext {
    if (_state == _NOT_MOVED_YET) _move();
    return _state == _HAS_NEXT_AND_NEXT_IN_CURRENT;
  }

  E next() {
    // Call to hasNext is necessary to make sure we are positioned at the first
    // element when we start iterating.
    if (!hasNext) throw new StateError("No more elements");
    assert(_state == _HAS_NEXT_AND_NEXT_IN_CURRENT);
    E result = _iterator.current;
    _move();
    return result;
  }

  void _move() {
    if (_iterator.moveNext()) {
      _state = _HAS_NEXT_AND_NEXT_IN_CURRENT;
    } else {
      _state = _NO_NEXT;
    }
  }
}
