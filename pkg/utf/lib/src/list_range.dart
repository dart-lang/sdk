// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf.list_range;

import 'dart:collection';

/**
 * _ListRange in an internal type used to create a lightweight Interable on a
 * range within a source list. DO NOT MODIFY the underlying list while
 * iterating over it. The results of doing so are undefined.
 */
// TODO(floitsch): Consider removing the extend and switch to implements since
// that's cheaper to allocate.
class ListRange extends IterableBase {
  final List _source;
  final int _offset;
  final int _length;

  ListRange(source, [offset = 0, length]) :
      this._source = source,
      this._offset = offset,
      this._length = (length == null ? source.length - offset : length) {
    if (_offset < 0 || _offset > _source.length) {
      throw new RangeError.value(_offset);
    }
    if (_length != null && (_length < 0)) {
      throw new RangeError.value(_length);
    }
    if (_length + _offset > _source.length) {
      throw new RangeError.value(_length + _offset);
    }
  }

  ListRangeIterator get iterator =>
      new _ListRangeIteratorImpl(_source, _offset, _offset + _length);

  int get length => _length;
}

/**
 * The ListRangeIterator provides more capabilities than a standard iterator,
 * including the ability to get the current position, count remaining items,
 * and move forward/backward within the iterator.
 */
abstract class ListRangeIterator implements Iterator<int> {
  bool moveNext();
  int get current;
  int get position;
  void backup([by]);
  int get remaining;
  void skip([count]);
}

class _ListRangeIteratorImpl implements ListRangeIterator {
  final List<int> _source;
  int _offset;
  final int _end;

  _ListRangeIteratorImpl(this._source, int offset, this._end)
      : _offset = offset - 1;

  int get current => _source[_offset];

  bool moveNext() => ++_offset < _end;

  int get position => _offset;

  void backup([int by = 1]) {
    _offset -= by;
  }

  int get remaining => _end - _offset - 1;

  void skip([int count = 1]) {
    _offset += count;
  }
}
