part of dart.collection;

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
    if (!hasNext) throw new StateError("No more elements");
    assert(_state == _HAS_NEXT_AND_NEXT_IN_CURRENT);
    E result = DDC$RT.cast(_iterator.current, dynamic, E, "CastGeneral",
        """line 33, column 16 of dart:collection/iterator.dart: """,
        _iterator.current is E, false);
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
