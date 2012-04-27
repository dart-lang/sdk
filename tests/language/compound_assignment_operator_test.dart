// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests that lhs of a compound assignement is executed only once.


class Indexed {
  Indexed() : _f = new List(10), count = 0 {
    _f[0] = 100;
    _f[1] = 200;
  }
  operator [](i) {
    count++;
    return _f;
  }
  var count;
  var _f;
}

class CompoundAssignmentOperatorTest {

  static void testIndexed() {
    Indexed indexed = new Indexed();
    Expect.equals(0, indexed.count);
    var tmp = indexed[0];
    Expect.equals(1, indexed.count);
    Expect.equals(100, indexed[4][0]);
    Expect.equals(2, indexed.count);
    Expect.equals(100, indexed[4][0]++);
    Expect.equals(3, indexed.count);
    Expect.equals(101, indexed[4][0]);
    Expect.equals(4, indexed.count);
    indexed[4][0] += 10;
    Expect.equals(5, indexed.count);
    Expect.equals(111, indexed[4][0]);
    var i = 0;
    indexed[3][i++] += 1;
    Expect.equals(1, i);
  }

  static void testMain() {
    testIndexed();
  }
}
main() {
  CompoundAssignmentOperatorTest.testMain();
}
