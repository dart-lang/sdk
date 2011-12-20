// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing arrays.

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

  static void testMain() {
    int len = 10;
    List a = new List(len);
    Expect.equals(true, a is List);
    Expect.equals(len, a.length);
    a.forEach(f(element) { Expect.equals(null, element); });
    a[1] = 1;
    Expect.equals(1, a[1]);
    bool exception_caught = false;
    try {
      var x = a[len];
    } catch (IndexOutOfRangeException e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);

    exception_caught = false;
    try {
      List a = new List(4);
      a.copyFrom(a, null, 1, 1);
    } catch (IllegalArgumentException e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);

    exception_caught = false;
    try {
      List a = new List(4);
      a.copyFrom(a, 10, 1, 1);
    } catch (IndexOutOfRangeException e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);

    exception_caught = false;
    try {
      List a = new List(4);
      List b = new List(4);
      b.copyFrom(a, 0, 0, 4);
    } catch (var e) {
      exception_caught = true;
    }
    Expect.equals(false, exception_caught);

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
    bool exceptionCaught = false;
    try {
      element = unsorted[2.1];
    } catch (IllegalArgumentException e) {
      exceptionCaught = true;
    } catch (TypeError e) {
      // For type checked mode.
      exceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);

    exceptionCaught = false;
    try {
      var a = new List(-1);
    } catch (Exception e) {  // Must agree which exception to throw.
      exceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);

    exceptionCaught = false;
    try {
      var a = new List(99999999999999999999999);  // Non-Smi.
    } catch (Exception e) {  // Must agree which exception to throw.
      exceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);

    exceptionCaught = false;
    List list = new List();
    try {
      list.removeLast();
    } catch (IndexOutOfRangeException e) {
      exceptionCaught = true;
    }
    Expect.equals(0, list.length);
    Expect.equals(true, exceptionCaught);
  }
}

main() {
  ListTest.testMain();
}
