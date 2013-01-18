// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library iterable_min_max_test;

import "dart:collection";

class C {
  final x;
  const C(this.x);
  int get hashCode => x.hashCode;
  bool operator==(var other) => other is C && x == other.x;
}

const inf = double.INFINITY;

var intList = const [0, 1, -1, -5, 5, -1000, 1000, -7, 7];
var doubleList = const [-0.0, 0.0, -1.0, 1.0, -1000.0, 1000.0, -inf, inf];
var stringList = const ["bbb", "bba", "bab", "abb", "bbc", "bcb", "cbb", "bb"];
var cList = const [const C(5), const C(3), const C(8),
                   const C(0), const C(10), const C(6)];
int compareC(C a, C b) => a.x.compareTo(b.x);


testMinMax(iterable, min, max) {
  Expect.equals(min, iterable.min());
  Expect.equals(min, iterable.min(Comparable.compare));
  Expect.equals(min, IterableMixinWorkaround.min(iterable));
  Expect.equals(min, IterableMixinWorkaround.min(iterable, Comparable.compare));
  Expect.equals(max, iterable.min((a, b) => Comparable.compare(b, a)));

  Expect.equals(max, iterable.max());
  Expect.equals(max, iterable.max(Comparable.compare));
  Expect.equals(max, IterableMixinWorkaround.max(iterable));
  Expect.equals(max, IterableMixinWorkaround.max(iterable, Comparable.compare));
  Expect.equals(min, iterable.max((a, b) => Comparable.compare(b, a)));
}


main() {
  testMinMax(const [], null, null);
  testMinMax([], null, null);
  testMinMax(new Set(), null, null);

  testMinMax(intList, -1000, 1000);  // Const list.
  testMinMax(new List.from(intList), -1000, 1000);  // Non-const list.
  testMinMax(new Set.from(intList), -1000, 1000);  // Set.

  testMinMax(doubleList, -inf, inf);
  testMinMax(new List.from(doubleList), -inf, inf);
  testMinMax(new Set.from(doubleList), -inf, inf);

  testMinMax(stringList, "abb", "cbb");
  testMinMax(new List.from(stringList), "abb", "cbb");
  testMinMax(new Set.from(stringList), "abb", "cbb");

  // Objects that are not Comparable.
  Expect.equals(const C(0), cList.min(compareC));
  Expect.equals(const C(0), IterableMixinWorkaround.min(cList, compareC));
  Expect.equals(const C(0), new List.from(cList).min(compareC));
  Expect.equals(const C(0), IterableMixinWorkaround.min(new List.from(cList), compareC));
  Expect.equals(const C(0), new Set.from(cList).min(compareC));
  Expect.equals(const C(0), IterableMixinWorkaround.min(new Set.from(cList), compareC));

  Expect.equals(const C(10), cList.max(compareC));
  Expect.equals(const C(10), IterableMixinWorkaround.max(cList, compareC));
  Expect.equals(const C(10), new List.from(cList).max(compareC));
  Expect.equals(const C(10), IterableMixinWorkaround.max(new List.from(cList), compareC));
  Expect.equals(const C(10), new Set.from(cList).max(compareC));
  Expect.equals(const C(10), IterableMixinWorkaround.max(new Set.from(cList), compareC));

  bool checkedMode = false;
  assert(checkedMode = true);
  Expect.throws(cList.min, (e) => checkedMode ? e is TypeError
                                              : e is NoSuchMethodError);
  Expect.throws(cList.max, (e) => checkedMode ? e is TypeError
                                              : e is NoSuchMethodError);
}

