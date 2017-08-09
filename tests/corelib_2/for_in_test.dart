// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ForInTest {
  static testMain() {
    testSimple();
    testBreak();
    testContinue();
    testClosure();
  }

  static Set<int> getSmallSet() {
    Set<int> set = new Set<int>();
    set.add(1);
    set.add(2);
    set.add(4);
    return set;
  }

  static void testSimple() {
    Set<int> set = getSmallSet();
    int count = 0;
    for (final i in set) {
      count += i;
    }
    Expect.equals(7, count);

    count = 0;
    for (var i in set) {
      count += i;
    }
    Expect.equals(7, count);

    count = 0;
    for (int i in set) {
      count += i;
    }
    Expect.equals(7, count);

    count = 0;
    for (final int i in set) {
      count += i;
    }
    Expect.equals(7, count);

    count = 0;
    int i = 0;
    Expect.equals(false, set.contains(i)); // Used to test [i] after loop.
    for (i in set) {
      count += i;
    }
    Expect.equals(7, count);
    Expect.equals(true, set.contains(i));
    // The default implementation of [Set] preserves order.
    Expect.equals(4, i);
  }

  static void testBreak() {
    Set<int> set = getSmallSet();
    int count = 0;
    for (final i in set) {
      if (i == 4) break;
      count += i;
    }
    Expect.equals(true, count < 4);
  }

  static void testContinue() {
    Set<int> set = getSmallSet();
    int count = 0;
    for (final i in set) {
      if (i < 4) continue;
      count += i;
    }
    Expect.equals(4, count);
  }

  static void testClosure() {
    Set<int> set = getSmallSet();
    List<Function> closures = new List(set.length);
    int index = 0;
    for (var i in set) {
      closures[index++] = () => i;
    }

    Expect.equals(index, set.length);
    Expect.equals(7, closures[0]() + closures[1]() + closures[2]());
  }
}

main() {
  ForInTest.testMain();
}
