// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library set_test;


import 'package:expect/expect.dart';
import "dart:collection";

void testMain(Set create()) {
  Set set = create();
  Expect.equals(0, set.length);
  set.add(1);
  Expect.equals(1, set.length);
  Expect.isTrue(set.contains(1));

  set.add(1);
  Expect.equals(1, set.length);
  Expect.isTrue(set.contains(1));

  set.remove(1);
  Expect.equals(0, set.length);
  Expect.isFalse(set.contains(1));

  for (int i = 0; i < 10; i++) {
    set.add(i);
  }

  Expect.equals(10, set.length);
  for (int i = 0; i < 10; i++) {
    Expect.isTrue(set.contains(i));
  }

  Expect.equals(10, set.length);

  for (int i = 10; i < 20; i++) {
    Expect.isFalse(set.contains(i));
  }

  // Test Set.forEach.
  int sum = 0;
  testForEach(int val) {
    sum += (val + 1);
  }

  set.forEach(testForEach);
  Expect.equals(10 + 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1, sum);

  Expect.isTrue(set.containsAll(set));

  // Test Set.map.
  testMap(int val) {
    return val * val;
  }

  Set mapped = set.map(testMap).toSet();
  Expect.equals(10, mapped.length);

  Expect.isTrue(mapped.contains(0));
  Expect.isTrue(mapped.contains(1));
  Expect.isTrue(mapped.contains(4));
  Expect.isTrue(mapped.contains(9));
  Expect.isTrue(mapped.contains(16));
  Expect.isTrue(mapped.contains(25));
  Expect.isTrue(mapped.contains(36));
  Expect.isTrue(mapped.contains(49));
  Expect.isTrue(mapped.contains(64));
  Expect.isTrue(mapped.contains(81));

  sum = 0;
  set.forEach(testForEach);
  Expect.equals(10 + 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1, sum);

  sum = 0;

  mapped.forEach(testForEach);
  Expect.equals(1 + 2 + 5 + 10 + 17 + 26 + 37 + 50 + 65 + 82, sum);

  // Test Set.filter.
  testFilter(int val) {
    return val.isEven;
  }

  Set filtered = set.where(testFilter).toSet();

  Expect.equals(5, filtered.length);

  Expect.isTrue(filtered.contains(0));
  Expect.isTrue(filtered.contains(2));
  Expect.isTrue(filtered.contains(4));
  Expect.isTrue(filtered.contains(6));
  Expect.isTrue(filtered.contains(8));

  sum = 0;
  filtered.forEach(testForEach);
  Expect.equals(1 + 3 + 5 + 7 + 9, sum);

  Expect.isTrue(set.containsAll(filtered));

  // Test Set.every.
  testEvery(int val) {
    return (val < 10);
  }

  Expect.isTrue(set.every(testEvery));
  Expect.isTrue(filtered.every(testEvery));

  filtered.add(10);
  Expect.isFalse(filtered.every(testEvery));

  // Test Set.some.
  testSome(int val) {
    return (val == 4);
  }

  Expect.isTrue(set.any(testSome));
  Expect.isTrue(filtered.any(testSome));
  filtered.remove(4);
  Expect.isFalse(filtered.any(testSome));

  // Test Set.intersection.
  Set intersection = set.intersection(filtered);
  Expect.isTrue(set.contains(0));
  Expect.isTrue(set.contains(2));
  Expect.isTrue(set.contains(6));
  Expect.isTrue(set.contains(8));
  Expect.isFalse(intersection.contains(1));
  Expect.isFalse(intersection.contains(3));
  Expect.isFalse(intersection.contains(4));
  Expect.isFalse(intersection.contains(5));
  Expect.isFalse(intersection.contains(7));
  Expect.isFalse(intersection.contains(9));
  Expect.isFalse(intersection.contains(10));
  Expect.equals(4, intersection.length);

  Expect.isTrue(set.containsAll(intersection));
  Expect.isTrue(filtered.containsAll(intersection));

  // Test Set.union.
  Set twice = create()..addAll([0, 2, 4, 6, 8, 10, 12, 14]);
  Set thrice = create()..addAll([0, 3, 6, 9, 12, 15]);
  Set union = twice.union(thrice);
  Expect.equals(11, union.length);
  for (int i = 0; i < 16; i++) {
    Expect.equals(i.isEven || (i % 3) == 0, union.contains(i));
  }

  // Test Set.difference.
  Set difference = twice.difference(thrice);
  Expect.equals(5, difference.length);
  for (int i = 0; i < 16; i++) {
    Expect.equals(i.isEven && (i % 3) != 0, difference.contains(i));
  }
  Expect.isTrue(twice.difference(thrice).difference(twice).isEmpty);

  // Test Set.addAll.
  List list = new List(10);
  for (int i = 0; i < 10; i++) {
    list[i] = i + 10;
  }
  set.addAll(list);
  Expect.equals(20, set.length);
  for (int i = 0; i < 20; i++) {
    Expect.isTrue(set.contains(i));
  }

  // Test Set.removeAll
  set.removeAll(list);
  Expect.equals(10, set.length);
  for (int i = 0; i < 10; i++) {
    Expect.isTrue(set.contains(i));
  }
  for (int i = 10; i < 20; i++) {
    Expect.isFalse(set.contains(i));
  }

  // Test Set.clear.
  set.clear();
  Expect.equals(0, set.length);
  set.add(11);
  Expect.equals(1, set.length);
}

main() {
  testMain(() => new Set());
  testMain(() => new HashSet());
}
