// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing the Expect class.

import "package:expect/expect.dart";

class ExpectTest {
  static testEquals(a) {
    try {
      Expect.equals("AB", a, "within testEquals");
    } on Exception catch (msg) {
      print(msg);
      return;
    }
    Expect.equals("AB", "${a}B");
    throw "Expect.equals did not fail";
  }

  static testIsTrue(f) {
    try {
      Expect.isTrue(f);
    } on Exception catch (msg) {
      print(msg);
      return;
    }
    Expect.isFalse(f);
    throw "Expect.isTrue did not fail";
  }

  static testIsFalse(t) {
    try {
      Expect.isFalse(t);
    } on Exception catch (msg) {
      print(msg);
      return;
    }
    Expect.isTrue(t);
    throw "Expect.isFalse did not fail";
  }

  static testIdentical(a) {
    var ab = "${a}B";
    try {
      Expect.identical("AB", ab);
    } on Exception catch (msg) {
      print(msg);
      return;
    }
    Expect.equals("AB", ab);
    throw "Expect.identical did not fail";
  }

  static testFail() {
    try {
      Expect.fail("fail now");
    } on Exception catch (msg) {
      print(msg);
      return;
    }
    throw "Expect.fail did not fail";
  }

  static void testMain() {
    testEquals("A");
    testIsTrue(false);
    testIsTrue(1);
    testIsFalse(true);
    testIsFalse(0);
    testIdentical("A");
    testFail();
  }
}

main() {
  ExpectTest.testMain();
}
