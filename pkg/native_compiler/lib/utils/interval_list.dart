// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'dart:math' show max;

/// Sorted list of disjoint [start, end) intervals
/// (start of each interval is inclusive, end is exclusive).
///
/// Supports prepending intervals in the descending order.
class IntervalList {
  static const initialCapacity = 4;

  // Sorted list of [start, end) pairs.
  Int32List _list;
  int _first;
  int _length = 0;

  factory IntervalList() => IntervalList._(initialCapacity);
  IntervalList._(int capacity) : _list = Int32List(capacity), _first = capacity;

  bool get isEmpty => _length == 0;

  int get length => _length;
  int startAt(int index) => _list[_first + (index << 1)];
  int endAt(int index) => _list[_first + (index << 1) + 1];

  /// Overwrite starting point of the given interval.
  void setStartAt(int index, int value) {
    assert(value >= 0);
    assert(value < endAt(index));
    assert(index == 0 || endAt(index - 1) < value);
    _setStartAt(index, value);
  }

  void _setStartAt(int index, int value) {
    assert(value >= 0);
    _list[_first + (index << 1)] = value;
  }

  void _setEndAt(int index, int value) {
    assert(value >= 0);
    _list[_first + (index << 1) + 1] = value;
  }

  int get start => startAt(0);
  int get end => endAt(length - 1);

  /// Add interval [start, end) to this list.
  ///
  /// Intervals should be added in the descending order by the end position.
  /// Intersecting intervals are not allowed except nested intervals with
  /// the same starting position (which are ignored).
  void addInterval(int start, int end) {
    assert(start >= 0);
    assert(end >= 0);
    assert(start < end);
    if (!isEmpty) {
      // Intervals should be added in descending order.
      assert(end < endAt(0));
      if (start == startAt(0)) {
        // Ignore nested interval.
        return;
      }
      // Intersecting intervals are not allowed.
      assert(end <= startAt(0));
      if (end == startAt(0)) {
        // Merge two adjacent intervals.
        _setStartAt(0, start);
        return;
      }
      // Add a new disjoint interval.
      if (_first == 0) {
        _expand(_list.length << 1);
      }
    }
    ++_length;
    _first -= 2;
    _setStartAt(0, start);
    _setEndAt(0, end);
  }

  void _expand(int capacity) {
    final newList = Int32List(capacity);
    newList.setRange(
      newList.length - (_length << 1),
      newList.length,
      _list,
      _first,
    );
    _list = newList;
    _first = newList.length - (_length << 1);
  }

  bool intersects(IntervalList other) {
    if (end <= other.start || other.end <= start) {
      return false;
    }
    return firstIntersection(0, other, 0) >= 0;
  }

  // Position of the first intersection between intervals index...length-1
  // of this list and intervals otherIndex...other.length-1 of [other].
  int firstIntersection(int index, IntervalList other, int otherIndex) {
    var i = index;
    var j = otherIndex;
    final len1 = length;
    final len2 = other.length;
    while (i < len1 && j < len2) {
      if (endAt(i) <= other.startAt(j)) {
        ++i;
      } else if (other.endAt(j) <= startAt(i)) {
        ++j;
      } else {
        return max(startAt(i), other.startAt(j));
      }
    }
    return -1;
  }

  /// Append disjoint list of intervals.
  void merge(IntervalList other) {
    final int otherLen = other.length;
    if (_first < (otherLen << 1)) {
      _expand((length + otherLen) << 1);
    }
    // Grow this list by otherLen.
    _first = _first - (otherLen << 1);
    assert(_first >= 0);
    _length = _length + otherLen;
    var dst = 0;
    void append(int start, int end) {
      assert(dst == 0 || endAt(dst - 1) <= start);
      if (dst != 0 && endAt(dst - 1) == start) {
        _setEndAt(dst - 1, end);
      } else {
        _setStartAt(dst, start);
        _setEndAt(dst, end);
        ++dst;
      }
    }

    var i = otherLen;
    var j = 0;
    while (i < length && j < other.length) {
      final start1 = startAt(i);
      final start2 = other.startAt(j);
      if (start1 < start2) {
        append(start1, endAt(i));
        ++i;
      } else {
        append(start2, other.endAt(j));
        ++j;
      }
    }
    // Copy tails.
    while (i < length) {
      append(startAt(i), endAt(i));
      ++i;
    }
    while (j < other.length) {
      append(other.startAt(j), other.endAt(j));
      ++j;
    }
    _length = dst;
  }

  /// Move out intervals after [pos] into a separate list.
  ///
  /// If [pos] belongs to an interval [start, end), then
  /// [start, pos) would belong to this list and [pos, end) is moved out.
  IntervalList splitAt(int pos) {
    var i = 0;
    for (; i < length; ++i) {
      if (endAt(i) > pos) {
        break;
      }
    }
    if (i == length) {
      return IntervalList();
    }
    int tailLen = length - i;
    final tail = IntervalList._(tailLen << 1);
    tail._first = 0;
    tail._length = tailLen;
    tail._list.setRange(0, tailLen << 1, _list, _first + (i << 1));
    if (startAt(i) < pos) {
      this._length = i + 1;
      _setEndAt(i, pos);
      tail._setStartAt(0, pos);
    } else {
      this._length = i;
    }
    return tail;
  }

  @override
  String toString() {
    final buf = StringBuffer();
    for (var i = 0; i < length; ++i) {
      if (i != 0) buf.write(', ');
      buf.write('[${startAt(i)}, ${endAt(i)})');
    }
    return buf.toString();
  }
}
