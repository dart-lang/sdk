// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

class ToStringAsFixedTest {
  static void testMain() {
    Expect.equals("2.000", 2.0.toStringAsFixed(3));
    Expect.equals("2.100", 2.1.toStringAsFixed(3));
    Expect.equals("2.120", 2.12.toStringAsFixed(3));
    Expect.equals("2.123", 2.123.toStringAsFixed(3));
    Expect.equals("2.124", 2.1239.toStringAsFixed(3));
    Expect.equals("NaN", (0.0 / 0.0).toStringAsFixed(3));
    Expect.equals("Infinity", (1.0 / 0.0).toStringAsFixed(3));
    Expect.equals("-Infinity", (-1.0 / 0.0).toStringAsFixed(3));
    Expect.equals(
        "1.1111111111111111e+21", 1111111111111111111111.0.toStringAsFixed(8));
    Expect.equals("0.1", 0.1.toStringAsFixed(1));
    Expect.equals("0.10", 0.1.toStringAsFixed(2));
    Expect.equals("0.100", 0.1.toStringAsFixed(3));
    Expect.equals("0.01", 0.01.toStringAsFixed(2));
    Expect.equals("0.010", 0.01.toStringAsFixed(3));
    Expect.equals("0.0100", 0.01.toStringAsFixed(4));
    Expect.equals("0.00", 0.001.toStringAsFixed(2));
    Expect.equals("0.001", 0.001.toStringAsFixed(3));
    Expect.equals("0.0010", 0.001.toStringAsFixed(4));
    Expect.equals("1.0000", 1.0.toStringAsFixed(4));
    Expect.equals("1.0", 1.0.toStringAsFixed(1));
    Expect.equals("1", 1.0.toStringAsFixed(0));
    Expect.equals("12", 12.0.toStringAsFixed(0));
    Expect.equals("1", 1.1.toStringAsFixed(0));
    Expect.equals("12", 12.1.toStringAsFixed(0));
    Expect.equals("1", 1.12.toStringAsFixed(0));
    Expect.equals("12", 12.12.toStringAsFixed(0));
    Expect.equals("0.0000006", 0.0000006.toStringAsFixed(7));
    Expect.equals("0.00000006", 0.00000006.toStringAsFixed(8));
    Expect.equals("0.000000060", 0.00000006.toStringAsFixed(9));
    Expect.equals("0.0000000600", 0.00000006.toStringAsFixed(10));
    Expect.equals("0", 0.0.toStringAsFixed(0));
    Expect.equals("0.0", 0.0.toStringAsFixed(1));
    Expect.equals("0.00", 0.0.toStringAsFixed(2));

    Expect.equals("-0.1", (-0.1).toStringAsFixed(1));
    Expect.equals("-0.10", (-0.1).toStringAsFixed(2));
    Expect.equals("-0.100", (-0.1).toStringAsFixed(3));
    Expect.equals("-0.01", (-0.01).toStringAsFixed(2));
    Expect.equals("-0.010", (-0.01).toStringAsFixed(3));
    Expect.equals("-0.0100", (-0.01).toStringAsFixed(4));
    Expect.equals("-0.00", (-0.001).toStringAsFixed(2));
    Expect.equals("-0.001", (-0.001).toStringAsFixed(3));
    Expect.equals("-0.0010", (-0.001).toStringAsFixed(4));
    Expect.equals("-1.0000", (-1.0).toStringAsFixed(4));
    Expect.equals("-1.0", (-1.0).toStringAsFixed(1));
    Expect.equals("-1", (-1.0).toStringAsFixed(0));
    Expect.equals("-1", (-1.1).toStringAsFixed(0));
    Expect.equals("-12", (-12.1).toStringAsFixed(0));
    Expect.equals("-1", (-1.12).toStringAsFixed(0));
    Expect.equals("-12", (-12.12).toStringAsFixed(0));
    Expect.equals("-0.0000006", (-0.0000006).toStringAsFixed(7));
    Expect.equals("-0.00000006", (-0.00000006).toStringAsFixed(8));
    Expect.equals("-0.000000060", (-0.00000006).toStringAsFixed(9));
    Expect.equals("-0.0000000600", (-0.00000006).toStringAsFixed(10));
    Expect.equals("-0", (-0.0).toStringAsFixed(0));
    Expect.equals("-0.0", (-0.0).toStringAsFixed(1));
    Expect.equals("-0.00", (-0.0).toStringAsFixed(2));

    Expect.equals("1000", 1000.0.toStringAsFixed(0));
    Expect.equals("0", 0.00001.toStringAsFixed(0));
    Expect.equals("0.00001", 0.00001.toStringAsFixed(5));
    Expect.equals(
        "0.00000000000000000010", 0.0000000000000000001.toStringAsFixed(20));
    Expect.equals("0.00001000000000000", 0.00001.toStringAsFixed(17));
    Expect.equals("1.00000000000000000", 1.0.toStringAsFixed(17));
    Expect.equals(
        "1000000000000000128", 1000000000000000128.0.toStringAsFixed(0));
    Expect.equals(
        "100000000000000128.0", 100000000000000128.0.toStringAsFixed(1));
    Expect.equals(
        "10000000000000128.00", 10000000000000128.0.toStringAsFixed(2));
    Expect.equals("10000000000000128.00000000000000000000",
        10000000000000128.0.toStringAsFixed(20));
    Expect.equals("0", 0.0.toStringAsFixed(0));
    Expect.equals("-42.000", (-42.0).toStringAsFixed(3));
    Expect.equals(
        "-1000000000000000128", (-1000000000000000128.0).toStringAsFixed(0));
    Expect.equals("-0.00000000000000000010",
        (-0.0000000000000000001).toStringAsFixed(20));
    Expect.equals(
        "0.12312312312312299889", 0.123123123123123.toStringAsFixed(20));
    // Test that we round up even when the last digit generated is even.
    // dtoa does not do this in its original form.
    Expect.equals("1", 0.5.toStringAsFixed(0));
    Expect.equals("-1", (-0.5).toStringAsFixed(0));
    Expect.equals("1.3", 1.25.toStringAsFixed(1));
    Expect.equals("234.2040", 234.20405.toStringAsFixed(4));
    Expect.equals("234.2041", 234.2040506.toStringAsFixed(4));
  }
}

main() {
  ToStringAsFixedTest.testMain();
}
