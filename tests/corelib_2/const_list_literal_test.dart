// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that a final list literal is not expandable nor modifiable.

class ConstListLiteralTest {
  static void testMain() {
    var list = const [4, 2, 3];
    Expect.equals(3, list.length);

    var exception = null;
    try {
      list.add(4);
    } on UnsupportedError catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
    Expect.equals(3, list.length);
    exception = null;

    exception = null;
    try {
      list.addAll([4, 5]);
    } on UnsupportedError catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
    Expect.equals(3, list.length);

    exception = null;
    try {
      list[0] = 0;
    } on UnsupportedError catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
    Expect.equals(3, list.length);

    exception = null;
    try {
      list.sort((a, b) => a - b);
    } on UnsupportedError catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
    Expect.equals(3, list.length);
    Expect.equals(4, list[0]);
    Expect.equals(2, list[1]);
    Expect.equals(3, list[2]);

    exception = null;
    try {
      list.setRange(0, 1, [1], 0);
    } on UnsupportedError catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
    Expect.equals(3, list.length);
    Expect.equals(4, list[0]);
    Expect.equals(2, list[1]);
    Expect.equals(3, list[2]);

    // Note: the next check is a regression test for dart2js. The immutable list
    // overrides the 'length' property of List, but relies on using the native
    // 'forEach' construct in Array. This test ensures that our strategy works
    // correctly.
    int x = 0;
    list.forEach((e) {
      x += e;
    });
    Expect.equals(9, x);
  }
}

main() {
  ConstListLiteralTest.testMain();
}
