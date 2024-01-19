// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  if (!webNumbers) {
    Expect.equals("0.0", (0.0).toString());
    Expect.equals("9.0", (9.0).toString());
    Expect.equals("90.0", (90.0).toString());
    Expect.equals(
        "111111111111111110000.0", (111111111111111111111.0).toString());
    Expect.equals("-9.0", (-9.0).toString());
    Expect.equals("-90.0", (-90.0).toString());
    Expect.equals(
        "-111111111111111110000.0", (-111111111111111111111.0).toString());
    Expect.equals("1000.0", (1000.0).toString());
    Expect.equals("1000000000000000100.0", (1000000000000000128.0).toString());
  } else {
    // Web number 'double's that are integral values print like 'int's
    Expect.equals("0", (0.0).toString());
    Expect.equals("9", (9.0).toString());
    Expect.equals("90", (90.0).toString());
    Expect.equals(
        "111111111111111110000", (111111111111111111111.0).toString());
    Expect.equals("-9", (-9.0).toString());
    Expect.equals("-90", (-90.0).toString());
    Expect.equals(
        "-111111111111111110000", (-111111111111111111111.0).toString());
    Expect.equals("1000", (1000.0).toString());
    Expect.equals("1000000000000000100", (1000000000000000128.0).toString());
  }
}
