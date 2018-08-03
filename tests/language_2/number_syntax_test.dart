// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class NumberSyntaxTest {
  static void testMain() {
    testShortDoubleSyntax();
    testDotSelectorSyntax();
  }

  static void testShortDoubleSyntax() {
    Expect.equals(0.0, .0);
    Expect.equals(0.5, .5);
    Expect.equals(0.1234, .1234);
  }

  static void testDotSelectorSyntax() {
    // Integers.
    Expect.equals('0', 0.toString());
    Expect.equals('1', 1.toString());
    Expect.equals('123', 123.toString());

    Expect.equals('0', 0.toString());
    Expect.equals('1', 1.toString());
    Expect.equals('123', 123.toString());

    Expect.equals('0', 0.toString());
    Expect.equals('1', 1.toString());
    Expect.equals('123', 123.toString());

    // Doubles.
    Expect.equals((0.0).toString(), 0.0.toString());
    Expect.equals((0.1).toString(), .1.toString());
    Expect.equals((1.1).toString(), 1.1.toString());
    Expect.equals((123.4).toString(), 123.4.toString());

    Expect.equals((0.0).toString(), 0.0.toString());
    Expect.equals((0.1).toString(), .1.toString());
    Expect.equals((1.1).toString(), 1.1.toString());
    Expect.equals((123.4).toString(), 123.4.toString());

    Expect.equals((0.0).toString(), 0.0.toString());
    Expect.equals((0.1).toString(), .1.toString());
    Expect.equals((1.1).toString(), 1.1.toString());
    Expect.equals((123.4).toString(), 123.4.toString());

    // Exponent notation.
    Expect.equals((0e0).toString(), 0e0.toString());
    Expect.equals((1e+1).toString(), 1e+1.toString());
    Expect.equals((2.1e-34).toString(), 2.1e-34.toString());
  }
}

main() {
  NumberSyntaxTest.testMain();
}
