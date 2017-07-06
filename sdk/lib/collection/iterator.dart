// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "collection.dart";

/**
 * The [HasNextIterator] class wraps an [Iterator] and provides methods to
 * iterate over an object using `hasNext` and `next`.
 *
 * An [HasNextIterator] does not implement the [Iterator] interface.
 */
class HasNextIterator<E> {
  static const int _HAS_NEXT_AND_NEXT_IN_CURRENT = 0;
  static const int _NO_NEXT = 1;
  static const int _NOT_MOVED_YET = 2;

  Iterator<E> _iterator;
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
