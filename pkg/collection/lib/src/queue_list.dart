// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/**
 * A class that efficiently implements both [Queue] and [List].
 */
// TODO(nweiz): Currently this code is copied almost verbatim from
// dart:collection. The only changes are to implement List and to remove methods
// that are redundant with ListMixin. Remove or simplify it when issue 21330 is
// fixed.
class QueueList<E> extends Object with ListMixin<E> implements Queue<E> {
  static const int _INITIAL_CAPACITY = 8;
  List<E> _table;
  int _head;
  int _tail;

  /**
   * Create an empty queue.
   *
   * If [initialCapacity] is given, prepare the queue for at least that many
   * elements.
   */
  QueueList([int initialCapacity]) : _head = 0, _tail = 0 {
    if (initialCapacity == null || initialCapacity < _INITIAL_CAPACITY) {
      initialCapacity = _INITIAL_CAPACITY;
    } else if (!_isPowerOf2(initialCapacity)) {
      initialCapacity = _nextPowerOf2(initialCapacity);
    }
    assert(_isPowerOf2(initialCapacity));
    _table = new List<E>(initialCapacity);
  }

  /**
   * Create a queue initially containing the elements of [source].
   */
  factory QueueList.from(Iterable<E> source) {
    if (source is List) {
      int length = source.length;
      QueueList<E> queue = new QueueList(length + 1);
      assert(queue._table.length > length);
      List sourceList = source;
      queue._table.setRange(0, length, sourceList, 0);
      queue._tail = length;
      return queue;
    } else {
      return new QueueList<E>()..addAll(source);
    }
  }

  // Collection interface.

  void add(E element) {
    _add(element);
  }

  void addAll(Iterable<E> elements) {
    if (elements is List) {
      List list = elements;
      int addCount = list.length;
      int length = this.length;
      if (length + addCount >= _table.length) {
        _preGrow(length + addCount);
        // After preGrow, all elements are at the start of the list.
        _table.setRange(length, length + addCount, list, 0);
        _tail += addCount;
      } else {
        // Adding addCount elements won't reach _head.
        int endSpace = _table.length - _tail;
        if (addCount < endSpace) {
          _table.setRange(_tail, _tail + addCount, list, 0);
          _tail += addCount;
        } else {
          int preSpace = addCount - endSpace;
          _table.setRange(_tail, _tail + endSpace, list, 0);
          _table.setRange(0, preSpace, list, endSpace);
          _tail = preSpace;
        }
      }
    } else {
      for (E element in elements) _add(element);
    }
  }

  String toString() => IterableBase.iterableToFullString(this, "{", "}");

  // Queue interface.

  void addLast(E element) { _add(element); }

  void addFirst(E element) {
    _head = (_head - 1) & (_table.length - 1);
    _table[_head] = element;
    if (_head == _tail) _grow();
  }

  E removeFirst() {
    if (_head == _tail) throw new StateError("No element");
    E result = _table[_head];
    _table[_head] = null;
    _head = (_head + 1) & (_table.length - 1);
    return result;
  }

  E removeLast() {
    if (_head == _tail) throw new StateError("No element");
    _tail = (_tail - 1) & (_table.length - 1);
    E result = _table[_tail];
    _table[_tail] = null;
    return result;
  }

  // List interface.

  int get length => (_tail - _head) & (_table.length - 1);

  void set length(int value) {
    if (value < 0) throw new RangeError("Length $value may not be negative.");

    int delta = value - length;
    if (delta >= 0) {
      if (_table.length <= value) {
        _preGrow(value);
      }
      _tail = (_tail + delta) & (_table.length - 1);
      return;
    }

    int newTail = _tail + delta; // [delta] is negative.
    if (newTail >= 0) {
      _table.fillRange(newTail, _tail, null);
    } else { 
      newTail += _table.length;
      _table.fillRange(0, _tail, null);
      _table.fillRange(newTail, _table.length, null);
    }
    _tail = newTail;
  }

  E operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError("Index $index must be in the range [0..$length).");
    }

    return _table[(_head + index) & (_table.length - 1)];
  }

  void operator[]=(int index, E value) {
    if (index < 0 || index >= length) {
      throw new RangeError("Index $index must be in the range [0..$length).");
    }

    _table[(_head + index) & (_table.length - 1)] = value;
  }

  // Internal helper functions.

  /**
   * Whether [number] is a power of two.
   *
   * Only works for positive numbers.
   */
  static bool _isPowerOf2(int number) => (number & (number - 1)) == 0;

  /**
   * Rounds [number] up to the nearest power of 2.
   *
   * If [number] is a power of 2 already, it is returned.
   *
   * Only works for positive numbers.
   */
  static int _nextPowerOf2(int number) {
    assert(number > 0);
    number = (number << 1) - 1;
    for(;;) {
      int nextNumber = number & (number - 1);
      if (nextNumber == 0) return number;
      number = nextNumber;
    }
  }

  /** Adds element at end of queue. Used by both [add] and [addAll]. */
  void _add(E element) {
    _table[_tail] = element;
    _tail = (_tail + 1) & (_table.length - 1);
    if (_head == _tail) _grow();
  }

  /**
   * Grow the table when full.
   */
  void _grow() {
    List<E> newTable = new List<E>(_table.length * 2);
    int split = _table.length - _head;
    newTable.setRange(0, split, _table, _head);
    newTable.setRange(split, split + _head, _table, 0);
    _head = 0;
    _tail = _table.length;
    _table = newTable;
  }

  int _writeToList(List<E> target) {
    assert(target.length >= length);
    if (_head <= _tail) {
      int length = _tail - _head;
      target.setRange(0, length, _table, _head);
      return length;
    } else {
      int firstPartSize = _table.length - _head;
      target.setRange(0, firstPartSize, _table, _head);
      target.setRange(firstPartSize, firstPartSize + _tail, _table, 0);
      return _tail + firstPartSize;
    }
  }

  /** Grows the table even if it is not full. */
  void _preGrow(int newElementCount) {
    assert(newElementCount >= length);

    // Add 1.5x extra room to ensure that there's room for more elements after
    // expansion.
    newElementCount += newElementCount >> 1;
    int newCapacity = _nextPowerOf2(newElementCount);
    List<E> newTable = new List<E>(newCapacity);
    _tail = _writeToList(newTable);
    _table = newTable;
    _head = 0;
  }
}
