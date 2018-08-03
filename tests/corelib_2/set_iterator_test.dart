// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class FixedHashCode {
  final int _hashCode;
  const FixedHashCode(this._hashCode);
  int get hashCode {
    return _hashCode;
  }
}

class SetIteratorTest {
  static testMain() {
    testSmallSet();
    testLargeSet();
    testEmptySet();
    testSetWithDeletedEntries();
    testBug5116829();
    testDifferentSizes();
    testDifferentHashCodes();
  }

  static int sum(int expected, Iterator<int> it) {
    int count = 0;
    while (it.moveNext()) {
      count += it.current;
    }
    Expect.equals(expected, count);
  }

  static void testSmallSet() {
    Set<int> set = new Set<int>();
    set.add(1);
    set.add(2);
    set.add(3);

    Iterator<int> it = set.iterator;
    sum(6, it);
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);
  }

  static void testLargeSet() {
    Set<int> set = new Set<int>();
    int count = 0;
    for (int i = 0; i < 100; i++) {
      count += i;
      set.add(i);
    }
    Iterator<int> it = set.iterator;
    sum(count, it);
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);
  }

  static void testEmptySet() {
    Set<int> set = new Set<int>();
    Iterator<int> it = set.iterator;
    sum(0, it);
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);
  }

  static void testSetWithDeletedEntries() {
    Set<int> set = new Set<int>();
    for (int i = 0; i < 100; i++) {
      set.add(i);
    }
    for (int i = 0; i < 100; i++) {
      set.remove(i);
    }
    Iterator<int> it = set.iterator;
    Expect.isFalse(it.moveNext());
    it = set.iterator;
    sum(0, it);
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);

    int count = 0;
    for (int i = 0; i < 100; i++) {
      set.add(i);
      if (i % 2 == 0)
        set.remove(i);
      else
        count += i;
    }
    it = set.iterator;
    sum(count, it);
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);
  }

  static void testBug5116829() {
    // During iteration we skipped slot 0 of the hashset's key list. "A" was
    // hashed to slot 0 and therefore triggered the bug.
    Set<String> mystrs = new Set<String>();
    mystrs.add("A");
    int seen = 0;
    for (String elt in mystrs) {
      seen++;
      Expect.equals("A", elt);
    }
    Expect.equals(1, seen);
  }

  static void testDifferentSizes() {
    for (int i = 1; i < 20; i++) {
      Set set = new Set();
      int sum = 0;
      for (int j = 0; j < i; j++) {
        set.add(j);
        sum += j;
      }
      int count = 0;
      int controlSum = 0;
      for (int x in set) {
        controlSum += x;
        count++;
      }
      Expect.equals(i, count);
      Expect.equals(sum, controlSum);
    }
  }

  static void testDifferentHashCodes() {
    for (int i = -20; i < 20; i++) {
      Set set = new Set();
      var element = new FixedHashCode(i);
      set.add(element);
      Expect.equals(1, set.length);
      bool foundIt = false;
      for (var x in set) {
        foundIt = true;
        Expect.equals(true, identical(x, element));
      }
      Expect.equals(true, foundIt);
    }
  }
}

main() {
  SetIteratorTest.testMain();
}
