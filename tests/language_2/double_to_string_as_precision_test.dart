// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  Expect.equals("NaN", (double.nan).toStringAsPrecision(1));
  Expect.equals("Infinity", (double.infinity).toStringAsPrecision(2));
  Expect.equals("-Infinity", (-double.infinity).toStringAsPrecision(2));
  Expect.equals("0.000555000000000000", (0.000555).toStringAsPrecision(15));
  Expect.equals("5.55000000000000e-7", (0.000000555).toStringAsPrecision(15));
  Expect.equals("-5.55000000000000e-7", (-0.000000555).toStringAsPrecision(15));
  Expect.equals("1e+8", (123456789.0).toStringAsPrecision(1));
  Expect.equals("123456789", (123456789.0).toStringAsPrecision(9));
  Expect.equals("1.2345679e+8", (123456789.0).toStringAsPrecision(8));
  Expect.equals("1.234568e+8", (123456789.0).toStringAsPrecision(7));
  Expect.equals("-1.234568e+8", (-123456789.0).toStringAsPrecision(7));
  Expect.equals("-1.2e-9", (-.0000000012345).toStringAsPrecision(2));
  Expect.equals("-1.2e-8", (-.000000012345).toStringAsPrecision(2));
  Expect.equals("-1.2e-7", (-.00000012345).toStringAsPrecision(2));
  Expect.equals("-0.0000012", (-.0000012345).toStringAsPrecision(2));
  Expect.equals("-0.000012", (-.000012345).toStringAsPrecision(2));
  Expect.equals("-0.00012", (-.00012345).toStringAsPrecision(2));
  Expect.equals("-0.0012", (-.0012345).toStringAsPrecision(2));
  Expect.equals("-0.012", (-.012345).toStringAsPrecision(2));
  Expect.equals("-0.12", (-.12345).toStringAsPrecision(2));
  Expect.equals("-1.2", (-1.2345).toStringAsPrecision(2));
  Expect.equals("-12", (-12.345).toStringAsPrecision(2));
  Expect.equals("-1.2e+2", (-123.45).toStringAsPrecision(2));
  Expect.equals("-1.2e+3", (-1234.5).toStringAsPrecision(2));
  Expect.equals("-1.2e+4", (-12345.0).toStringAsPrecision(2));
  Expect.equals("-1.235e+4", (-12345.67).toStringAsPrecision(4));
  Expect.equals("-1.234e+4", (-12344.67).toStringAsPrecision(4));
  Expect.equals("-0.0", (-0.0).toStringAsPrecision(2));
  Expect.equals("-0", (-0.0).toStringAsPrecision(1));
  // Test that we round up even when the last digit generated is even.
  // dtoa does not do this in its original form.
  Expect.equals("1.3", 1.25.toStringAsPrecision(2));
  Expect.equals("1.4", 1.35.toStringAsPrecision(2));
}
