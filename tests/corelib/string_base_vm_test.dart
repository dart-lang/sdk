// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing class 'StringBase' (currently VM specific).

library string_base_test;

import "package:expect/expect.dart";

class StringBaseTest {
  StringBaseTest() {}

  toString() {
    return "StringBase Tester";
  }

  static testInterpolation() {
    var answer = 40 + 2;
    var s = "The answer is $answer.";
    Expect.equals("The answer is 42.", s);

    int numBottles = 33;
    String wall = "wall";
    s = "${numBottles*3} bottles of beer on the $wall.";
    Expect.equals("99 bottles of beer on the wall.", s);
  }

  static testCreation() {
    String s = "Hello";
    List<int> a = new List(s.length);
    List<int> ga = new List();
    bool exception_caught = false;
    for (int i = 0; i < a.length; i++) {
      a[i] = s.codeUnitAt(i);
      ga.add(s.codeUnitAt(i));
    }
    try {
      String s4 = new String.fromCharCodes([0.0]);
    } on ArgumentError catch (ex) {
      exception_caught = true;
    } on TypeError catch (ex) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
    exception_caught = false;
    try {
      String s4 = new String.fromCharCodes([-1]);
    } on ArgumentError catch (ex) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
  }

  static testSubstring() {
    String s = "Hello World";
    Expect.equals("World", s.substring(6, s.length));
    Expect.equals("", s.substring(8, 8));
    bool exception_caught = false;
    try {
      s.substring(5, 12);
    } on RangeError catch (ex) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
    exception_caught = false;
    try {
      s.substring(5, 4);
    } on RangeError catch (ex) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
  }

  static void testMain() {
    testInterpolation();
    testCreation();
    testSubstring();
  }
}

main() {
  StringBaseTest.testMain();
}
