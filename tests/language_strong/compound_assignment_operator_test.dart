// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests that lhs of a compound assignment is executed only once.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

class Indexed {
  Indexed()
      : _f = new List(10),
        count = 0 {
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

var result;

class A {
  get field {
    result.add(1);
    return 1;
  }

  set field(value) {}

  static get static_field {
    result.add(0);
    return 1;
  }

  static set static_field(value) {
    result.add(1);
  }
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

  static testIndexedMore() {
    result = [];
    array() {
      result.add(0);
      return [0];
    }

    index() {
      result.add(1);
      return 0;
    }

    middle() {
      result.add(2);
    }

    sequence(a, b, c) {
      result.add(3);
    }

    sequence(array()[index()] += 1, middle(), array()[index()] += 1);
    Expect.listEquals([0, 1, 2, 0, 1, 3], result);
  }

  static testIndexedMoreMore() {
    result = [];
    middle() {
      result.add(2);
    }

    obj() {
      result.add(0);
      return new A();
    }

    sequence(a, b, c) {
      result.add(3);
    }

    sequence(obj().field += 1, middle(), obj().field += 1);
    Expect.listEquals([0, 1, 2, 0, 1, 3], result);

    result = [];
    sequence(A.static_field++, middle(), A.static_field++);
    Expect.listEquals([0, 1, 2, 0, 1, 3], result);
  }

  static void testMain() {
    for (int i = 0; i < 20; i++) {
      testIndexed();
      testIndexedMore();
      testIndexedMoreMore();
    }
  }
}

main() {
  CompoundAssignmentOperatorTest.testMain();
}
