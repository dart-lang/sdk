// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing arrays.

import "package:expect/expect.dart";

class A {}

class B {}

class ListTest {
  static void TestIterator() {
    List<int> a = new List<int>(10);
    int count = 0;

    // Basic iteration over ObjectList.
    for (int elem in a) {
      Expect.equals(null, elem);
      count++;
    }
    Expect.equals(10, count);

    // List length is 0.
    List<int> fa = new List<int>();
    count = 0;
    for (int elem in fa) {
      count++;
    }
    Expect.equals(0, count);

    // Iterate over ImmutableList.
    List<int> ca = const [0, 1, 2, 3, 4, 5];
    int sum = 0;
    for (int elem in ca) {
      sum += elem;
      fa.add(elem);
    }
    Expect.equals(15, sum);

    // Iterate over List.
    int sum2 = 0;
    for (int elem in fa) {
      sum2 += elem;
    }
    Expect.equals(sum, sum2);
  }

  static void testSublistTypeArguments() {
    final list1 = new List<A>(0).sublist(0);
    Expect.isTrue(list1 is List<A>);
    Expect.isTrue(list1 is! List<B>);

    final list2 = new List<A>(0).toList(growable: false);
    Expect.isTrue(list2 is List<A>);
    Expect.isTrue(list2 is! List<B>);
  }

  static void testMain() {
    int len = 10;
    List a = new List(len);
    Expect.equals(true, a is List);
    Expect.equals(len, a.length);
    a.forEach((element) {
      Expect.equals(null, element);
    });
    a[1] = 1;
    Expect.equals(1, a[1]);
    Expect.throwsRangeError(() => a[len]);

    Expect.throws(() {
      List a = new List(4);
      a.setRange(1, 2, a, null);
    });

    Expect.throws(() {
      List a = new List(4);
      a.setRange(1, 2, const [1, 2, 3, 4], null);
    });

    Expect.throwsRangeError(() {
      List a = new List(4);
      a.setRange(10, 11, a, 1);
    });

    a = new List(4);
    List b = new List(4);
    b.setRange(0, 4, a, 0);

    List<int> unsorted = [4, 3, 9, 12, -4, 9];
    int compare(a, b) {
      if (a < b) return -1;
      if (a > b) return 1;
      return 0;
    }

    unsorted.sort(compare);
    Expect.equals(6, unsorted.length);
    Expect.equals(-4, unsorted[0]);
    Expect.equals(12, unsorted[unsorted.length - 1]);
    int compare2(a, b) {
      if (a < b) return 1;
      if (a > b) return -1;
      return 0;
    }

    unsorted.sort(compare2);
    Expect.equals(12, unsorted[0]);
    Expect.equals(-4, unsorted[unsorted.length - 1]);
    Set<int> t = new Set<int>.from(unsorted);
    Expect.equals(true, t.contains(9));
    Expect.equals(true, t.contains(-4));
    Expect.equals(false, t.contains(-3));
    Expect.equals(6, unsorted.length);
    Expect.equals(5, t.length);
    TestIterator();
    int element = unsorted[2];
    Expect.equals(9, element);

    Expect.throws(() => new List(-1));
    Expect.throws(() => new List(0x7fffffffffffffff));

    List list = new List();
    Expect.throwsRangeError(list.removeLast);
    Expect.equals(0, list.length);
  }
}

main() {
  ListTest.testMain();
  ListTest.testSublistTypeArguments();
}
