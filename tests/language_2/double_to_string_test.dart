// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  Expect.equals("NaN", (double.nan).toString());
  Expect.equals("Infinity", (1 / 0).toString());
  Expect.equals("-Infinity", (-1 / 0).toString());
  Expect.equals("90.12", (90.12).toString());
  Expect.equals("0.1", (0.1).toString());
  Expect.equals("0.01", (0.01).toString());
  Expect.equals("0.0123", (0.0123).toString());
  Expect.equals(
      "1.1111111111111111e+21", (1111111111111111111111.0).toString());
  Expect.equals(
      "1.1111111111111111e+22", (11111111111111111111111.0).toString());
  Expect.equals("0.00001", (0.00001).toString());
  Expect.equals("0.000001", (0.000001).toString());
  Expect.equals("1e-7", (0.0000001).toString());
  Expect.equals("1.2e-7", (0.00000012).toString());
  Expect.equals("1.23e-7", (0.000000123).toString());
  Expect.equals("1e-8", (0.00000001).toString());
  Expect.equals("1.2e-8", (0.000000012).toString());
  Expect.equals("1.23e-8", (0.0000000123).toString());

  Expect.equals("-0.0", (-0.0).toString());
  Expect.equals("-90.12", (-90.12).toString());
  Expect.equals("-0.1", (-0.1).toString());
  Expect.equals("-0.01", (-0.01).toString());
  Expect.equals("-0.0123", (-0.0123).toString());
  Expect.equals(
      "-1.1111111111111111e+21", (-1111111111111111111111.0).toString());
  Expect.equals(
      "-1.1111111111111111e+22", (-11111111111111111111111.0).toString());
  Expect.equals("-0.00001", (-0.00001).toString());
  Expect.equals("-0.000001", (-0.000001).toString());
  Expect.equals("-1e-7", (-0.0000001).toString());
  Expect.equals("-1.2e-7", (-0.00000012).toString());
  Expect.equals("-1.23e-7", (-0.000000123).toString());
  Expect.equals("-1e-8", (-0.00000001).toString());
  Expect.equals("-1.2e-8", (-0.000000012).toString());
  Expect.equals("-1.23e-8", (-0.0000000123).toString());

  Expect.equals("0.00001", (0.00001).toString());
  Expect.equals("1e+21", (1000000000000000012800.0).toString());
  Expect.equals("-1e+21", (-1000000000000000012800.0).toString());
  Expect.equals("1e-7", (0.0000001).toString());
  Expect.equals("-1e-7", (-0.0000001).toString());
  Expect.equals(
      "1.0000000000000001e+21", (1000000000000000128000.0).toString());
  Expect.equals("0.000001", (0.000001).toString());
  Expect.equals("1e-7", (0.0000001).toString());
}
