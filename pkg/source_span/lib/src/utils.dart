// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_span.utils;

/// Returns the minimum of [obj1] and [obj2] according to
/// [Comparable.compareTo].
Comparable min(Comparable obj1, Comparable obj2) =>
    obj1.compareTo(obj2) > 0 ? obj2 : obj1;

/// Returns the maximum of [obj1] and [obj2] according to
/// [Comparable.compareTo].
Comparable max(Comparable obj1, Comparable obj2) =>
    obj1.compareTo(obj2) > 0 ? obj1 : obj2;

/// Find the first entry in a sorted [list] that matches a monotonic predicate.
///
/// Given a result `n`, that all items before `n` will not match, `n` matches,
/// and all items after `n` match too. The result is -1 when there are no
/// items, 0 when all items match, and list.length when none does.
int binarySearch(List list, bool matches(item)) {
  if (list.length == 0) return -1;
  if (matches(list.first)) return 0;
  if (!matches(list.last)) return list.length;

  int min = 0;
  int max = list.length - 1;
  while (min < max) {
    var half = min + ((max - min) ~/ 2);
    if (matches(list[half])) {
      max = half;
    } else {
      min = half + 1;
    }
  }
  return max;
}

