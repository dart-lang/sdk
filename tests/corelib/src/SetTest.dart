// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SetTest {

  static testMain() {
    Set set = new Set();
    Expect.equals(0, set.length);
    set.add(1);
    Expect.equals(1, set.length);
    Expect.equals(true, set.contains(1));

    set.add(1);
    Expect.equals(1, set.length);
    Expect.equals(true, set.contains(1));

    set.remove(1);
    Expect.equals(0, set.length);
    Expect.equals(false, set.contains(1));

    for (int i = 0; i < 10; i++) {
      set.add(i);
    }

    Expect.equals(10, set.length);
    for (int i = 0; i < 10; i++) {
      Expect.equals(true, set.contains(i));
    }

    Expect.equals(10, set.length);

    for (int i = 10; i < 20; i++) {
      Expect.equals(false, set.contains(i));
    }

    // Test Set.forEach.
    int sum = 0;
    testForEach(int val) {
      sum += (val + 1);
    }

    set.forEach(testForEach);
    Expect.equals(10 + 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1, sum);

    Expect.equals(true, set.isSubsetOf(set));
    Expect.equals(true, set.containsAll(set));

    // Test Set.map.
    testMap(int val) {
      return val * val;
    }

    Set mapped = set.map(testMap);
    Expect.equals(10, mapped.length);

    Expect.equals(true, mapped.contains(0));
    Expect.equals(true, mapped.contains(1));
    Expect.equals(true, mapped.contains(4));
    Expect.equals(true, mapped.contains(9));
    Expect.equals(true, mapped.contains(16));
    Expect.equals(true, mapped.contains(25));
    Expect.equals(true, mapped.contains(36));
    Expect.equals(true, mapped.contains(49));
    Expect.equals(true, mapped.contains(64));
    Expect.equals(true, mapped.contains(81));

    sum = 0;
    set.forEach(testForEach);
    Expect.equals(10 + 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1, sum);

    sum = 0;

    mapped.forEach(testForEach);
    Expect.equals(1 + 2 + 5 + 10 + 17 + 26 + 37 + 50 + 65 + 82, sum);

    // Test Set.filter.
    testFilter(int val) {
      return val.isEven();
    }

    Set filtered = set.filter(testFilter);

    Expect.equals(5, filtered.length);

    Expect.equals(true, filtered.contains(0));
    Expect.equals(true, filtered.contains(2));
    Expect.equals(true, filtered.contains(4));
    Expect.equals(true, filtered.contains(6));
    Expect.equals(true, filtered.contains(8));

    sum = 0;
    filtered.forEach(testForEach);
    Expect.equals(1 + 3 + 5 + 7 + 9, sum);

    Expect.equals(true, set.containsAll(filtered));
    Expect.equals(true, filtered.isSubsetOf(set));

    // Test Set.every.
    testEvery(int val) {
      return (val < 10);
    }

    Expect.equals(true, set.every(testEvery));
    Expect.equals(true, filtered.every(testEvery));

    filtered.add(10);
    Expect.equals(false, filtered.every(testEvery));

    // Test Set.some.
    testSome(int val) {
      return (val == 4);
    }

    Expect.equals(true, set.some(testSome));
    Expect.equals(true, filtered.some(testSome));
    filtered.remove(4);
    Expect.equals(false, filtered.some(testSome));

    // Test Set.intersection.
    Set intersection = set.intersection(filtered);
    Expect.equals(true, set.contains(0));
    Expect.equals(true, set.contains(2));
    Expect.equals(true, set.contains(6));
    Expect.equals(true, set.contains(8));
    Expect.equals(false, intersection.contains(1));
    Expect.equals(false, intersection.contains(3));
    Expect.equals(false, intersection.contains(4));
    Expect.equals(false, intersection.contains(5));
    Expect.equals(false, intersection.contains(7));
    Expect.equals(false, intersection.contains(9));
    Expect.equals(false, intersection.contains(10));
    Expect.equals(4, intersection.length);

    Expect.equals(true, set.containsAll(intersection));
    Expect.equals(true, filtered.containsAll(intersection));
    Expect.equals(true, intersection.isSubsetOf(set));
    Expect.equals(true, intersection.isSubsetOf(filtered));

    // Test Set.addAll.
    List list = new List(10);
    for (int i = 0; i < 10; i++) {
      list[i] = i + 10;
    }
    set.addAll(list);
    Expect.equals(20, set.length);
    for (int i = 0; i < 20; i++) {
      Expect.equals(true, set.contains(i));
    }

    // Test Set.removeAll
    set.removeAll(list);
    Expect.equals(10, set.length);
    for (int i = 0; i < 10; i++) {
      Expect.equals(true, set.contains(i));
    }
    for (int i = 10; i < 20; i++) {
      Expect.equals(false, set.contains(i));
    }

    // Test Set.clear.
    set.clear();
    Expect.equals(0, set.length);
    set.add(11);
    Expect.equals(1, set.length);
  }
}

main() {
  SetTest.testMain();
}
