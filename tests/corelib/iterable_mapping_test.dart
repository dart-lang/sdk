// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  List<int> list1 = <int>[1, 2, 3];
  List<int> list2 = const <int>[4, 5];
  List<String> list3 = <String>[];
  Set<int> set1 = new Set<int>();
  set1.addAll([11, 12, 13]);
  Set set2 = new Set();

  Iterable mapped = list1.mappedBy((x) => x + 1);
  Expect.isTrue(mapped is List);
  Expect.listEquals([2, 3, 4], mapped);

  mapped = mapped.mappedBy((x) => x + 1);
  Expect.isTrue(mapped is List);
  Expect.listEquals([3, 4, 5], mapped);

  mapped = list2.mappedBy((x) => x + 1);
  Expect.isTrue(mapped is List);
  Expect.listEquals([5, 6], mapped);

  mapped = mapped.mappedBy((x) => x + 1);
  Expect.isTrue(mapped is List);
  Expect.listEquals([6, 7], mapped);

  mapped = list3.mappedBy((x) => x + 1);
  Expect.isTrue(mapped is List);
  Expect.listEquals([], mapped);

  mapped = mapped.mappedBy((x) => x + 1);
  Expect.isTrue(mapped is List);
  Expect.listEquals([], mapped);

  var expected = new Set<int>()..addAll([12, 13, 14]);
  mapped = set1.mappedBy((x) => x + 1);
  Expect.isFalse(mapped is List);
  Expect.setEquals(expected, mapped.toSet());

  expected = new Set<int>()..addAll([13, 14, 15]);
  mapped = mapped.mappedBy((x) => x + 1);
  Expect.isFalse(mapped is List);
  Expect.setEquals(expected, mapped.toSet());

  mapped = set2.mappedBy((x) => x + 1);
  Expect.isFalse(mapped is List);
  Expect.listEquals([], mapped.toList());

  mapped = mapped.mappedBy((x) => x + 1);
  Expect.isFalse(mapped is List);
  Expect.listEquals([], mapped.toList());

}