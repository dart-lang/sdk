// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing parsing of "standard" types.

import "package:expect/expect.dart";

class ParseTypesTest {
  static bool callBool1() {
    return true;
  }

  static bool callBool2() {
    return false;
  }

  static int callInt() {
    return 2;
  }

  static String callString() {
    return "Hey";
  }

  static double callDouble() {
    return 4.0;
  }

  static void testMain() {
    Expect.equals(true, ParseTypesTest.callBool1());
    Expect.equals(false, ParseTypesTest.callBool2());
    Expect.equals(2, ParseTypesTest.callInt());
    Expect.equals("Hey", ParseTypesTest.callString());
    Expect.equals(4.0, ParseTypesTest.callDouble());
  }
}

main() {
  ParseTypesTest.testMain();
}
