// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests map literals.

class MapLiteralTest {
  MapLiteralTest() {}

  static testMain() {
    var test = new MapLiteralTest();
    test.testStaticInit();
    test.testConstInit();
  }

  testStaticInit() {
    var testClass = new StaticInit();
    testClass.test();
  }

  testConstInit() {
    var testClass = new ConstInit();
    testClass.test();
  }

  testLocalInit() {
    // Test construction of static const map literals
    var map1 = {"a": 1, "b": 2};
    // Test construction of static const map literals, with numbers
    var map2 = {"1": 1, "2": 2};

    Expect.equals(1, map1["a"]);
    Expect.equals(2, map1["b"]);

    Expect.equals(1, map2["1"]);
    Expect.equals(2, map2["2"]);
  }
}

class StaticInit {
  StaticInit() {}

  // Test construction of static const map literals
  static const map1 = const {"a": 1, "b": 2};
  // Test construction of static const map literals, with numbers
  static const map2 = const {"1": 1, "2": 2};

  test() {
    Expect.equals(1, map1["a"]);
    Expect.equals(2, map1["b"]);

    Expect.equals(1, map2["1"]);
    Expect.equals(2, map2["2"]);
  }
}

class ConstInit {
  final map1;
  final map2;

  ConstInit()
      : this.map1 = {"a": 1, "b": 2},
        this.map2 = {"1": 1, "2": 2} {}

  test() {
    Expect.equals(1, map1["a"]);
    Expect.equals(2, map1["b"]);

    Expect.equals(1, map2["1"]);
    Expect.equals(2, map2["2"]);
  }
}

main() {
  MapLiteralTest.testMain();
}
