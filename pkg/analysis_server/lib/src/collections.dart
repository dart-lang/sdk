// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Returns the concatenation of the input [iterables].
 *
 * The returned iterable is a lazily-evaluated view on the input iterables.
 */
Iterable<E> concat<E>(Iterable<Iterable<E>> iterables) =>
    iterables.expand((x) => x);

/**
 * Returns the concatenation of the input [iterables] as a [List].
 */
List<E> concatToList<E>(Iterable<Iterable<E>> iterables) =>
    concat(iterables).toList();

/**
 * Returns the given [list] if it is not empty, or `null` otherwise.
 */
List<E> nullIfEmpty<E>(List<E> list) {
  if (list == null) {
    return null;
  }
  if (list.isEmpty) {
    return null;
  }
  return list;
}

/// A pair of values.
class Pair<E, F> {
  final E first;
  final F last;

  Pair(this.first, this.last);

  int get hashCode => first.hashCode ^ last.hashCode;

  bool operator ==(other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }

  String toString() => '($first, $last)';
}

/**
 * A container that remembers the last `n` items added to it.
 *
 * It will never grow larger than [capacity]. It's a LIFO queue - the last item
 * added will be the first one returned from [items].
 */
class RecentBuffer<T> {
  final int capacity;

  List<T> _buffer = [];

  RecentBuffer(this.capacity);

  Iterable<T> get items => _buffer.reversed;

  void add(T item) {
    _buffer.add(item);

    if (_buffer.length > capacity) {
      _buffer.removeAt(0);
    }
  }
}
