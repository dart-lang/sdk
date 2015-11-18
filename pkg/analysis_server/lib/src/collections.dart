// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library collections;

/**
 * Returns the concatentation of the input iterables.
 *
 * The returned iterable is a lazily-evaluated view on the input iterables.
 */
Iterable concat(Iterable<Iterable> iterables) => iterables.expand((x) => x);

/**
 * Returns the concatentation of the input iterables as a [List].
 */
List concatToList(Iterable<Iterable> iterables) => concat(iterables).toList();

/**
 * Returns the given [list] if it is not empty, or `null` otherwise.
 */
List nullIfEmpty(List list) {
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
