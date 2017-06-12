// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Basic implementation of a heap, with O(log n) insertion and removal.
abstract class Heap<T> {
  final _items = <T>[];

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  void add(T item) {
    int index = _items.length;
    _items.length += 1;
    while (index > 0) {
      T parent = _items[_parentIndex(index)];
      if (sortsBefore(parent, item)) break;
      _items[index] = parent;
      index = _parentIndex(index);
    }
    _items[index] = item;
  }

  T remove() {
    T removed = _items[0];
    T orphan = _items.removeLast();
    if (_items.isNotEmpty) _reInsert(orphan);
    return removed;
  }

  /// Client should use a derived class to specify the sort order.
  bool sortsBefore(T a, T b);

  int _firstChildIndex(int index) {
    return (index << 1) + 1;
  }

  int _parentIndex(int index) {
    return (index - 1) >> 1;
  }

  void _reInsert(T item) {
    int index = 0;
    while (true) {
      int childIndex = _firstChildIndex(index);
      if (childIndex >= _items.length) break;
      T child = _items[childIndex];
      if (childIndex + 1 < _items.length) {
        T nextChild = _items[childIndex + 1];
        if (sortsBefore(nextChild, child)) {
          child = nextChild;
          childIndex++;
        }
      }
      if (sortsBefore(item, child)) break;
      _items[index] = _items[childIndex];
      index = childIndex;
    }
    _items[index] = item;
  }
}
