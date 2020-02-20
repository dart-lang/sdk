// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns the given [list] if it is not empty, or `null` otherwise.
List<E> nullIfEmpty<E>(List<E> list) {
  if (list == null) {
    return null;
  }
  if (list.isEmpty) {
    return null;
  }
  return list;
}

/// A container that remembers the last `n` items added to it.
///
/// It will never grow larger than [capacity]. It's a LIFO queue - the last item
/// added will be the first one returned from [items].
class RecentBuffer<T> {
  final int capacity;

  final List<T> _buffer = [];

  RecentBuffer(this.capacity);

  Iterable<T> get items => _buffer.reversed;

  void add(T item) {
    _buffer.add(item);

    if (_buffer.length > capacity) {
      _buffer.removeAt(0);
    }
  }
}
