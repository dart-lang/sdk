// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  List<int> list1 = <int>[1, 2, 3];
  List<int> list2 = const <int>[4, 5];
  List<String> list3 = <String>[];
  Set<int> set1 = new Set<int>();
  set1.addAll([11, 12, 13]);
  Set set2 = new Set();

  Iterable mapped = list1.map((x) => x + 1);
  Expect.listEquals([2, 3, 4], mapped.toList());

  mapped = mapped.map((x) => x + 1);
  Expect.listEquals([3, 4, 5], mapped.toList());

  mapped = list2.map((x) => x + 1);
  Expect.listEquals([5, 6], mapped.toList());

  mapped = mapped.map((x) => x + 1);
  Expect.listEquals([6, 7], mapped.toList());

  mapped = list3.map((x) => x + 1);
  Expect.listEquals([], mapped.toList());

  mapped = mapped.map((x) => x + 1);
  Expect.listEquals([], mapped.toList());

  var expected = new Set<int>()..addAll([12, 13, 14]);
  mapped = set1.map((x) => x + 1);
  Expect.isFalse(mapped is List);
  Expect.setEquals(expected, mapped.toSet());

  expected = new Set<int>()..addAll([13, 14, 15]);
  mapped = mapped.map((x) => x + 1);
  Expect.isFalse(mapped is List);
  Expect.setEquals(expected, mapped.toSet());

  mapped = set2.map((x) => x + 1);
  Expect.isFalse(mapped is List);
  Expect.listEquals([], mapped.toList());

  mapped = mapped.map((x) => x + 1);
  Expect.isFalse(mapped is List);
  Expect.listEquals([], mapped.toList());
}
