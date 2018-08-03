// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  Expect.equals(
      "0.000555000000000000046248", (0.000555).toStringAsPrecision(21));
  Expect.equals(0.000555000000000000046248, 0.000555);
  Expect.equals(
      "5.54999999999999980179e-7", (0.000000555).toStringAsPrecision(21));
  Expect.equals(5.54999999999999980179e-7, 0.000000555);
  Expect.equals(
      "-5.54999999999999980179e-7", (-0.000000555).toStringAsPrecision(21));
  Expect.equals(-5.54999999999999980179e-7, -0.000000555);
}
