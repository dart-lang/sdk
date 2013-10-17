// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.multiset;

import 'dart:collection';

/// A set of objects where each object can appear multiple times.
///
/// Like a set, this has amortized O(1) insertion, removal, and
/// existence-checking of elements. Counting the number of copies of an element
/// in the set is also amortized O(1).
///
/// Distinct elements retain insertion order. Additional copies of an element
/// beyond the first are grouped with the original element.
///
/// If multiple equal elements are added, only the first actual object is
/// retained.
class Multiset<E> extends IterableBase<E> {
  /// A map from each element in the set to the number of copies of that element
  /// in the set.
  final _map = new Map<E, int>();

  Iterator<E> get iterator {
    return _map.keys.expand((element) {
      return new Iterable.generate(_map[element], (_) => element);
    }).iterator;
  }

  Multiset()
      : super();

  /// Creates a multi-set and initializes it using the contents of [other].
  Multiset.from(Iterable<E> other)
      : super() {
    other.forEach(add);
  }

  /// Adds [value] to the set.
  void add(E value) {
    _map.putIfAbsent(value, () => 0);
    _map[value] += 1;
  }

  /// Removes one copy of [value] from the set.
  ///
  /// Returns whether a copy of [value] was removed, regardless of whether more
  /// copies remain.
  bool remove(E value) {
    if (!_map.containsKey(value)) return false;

    _map[value] -= 1;
    if (_map[value] == 0) _map.remove(value);
    return true;
  }

  /// Returns whether [value] is in the set.
  bool contains(E value) => _map.containsKey(value);

  /// Returns the number of copies of [value] in the set.
  int count(E value) => _map.containsKey(value) ? _map[value] : 0;
}
