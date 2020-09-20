// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no-intrinsify

// Test that math runtime function (non-intrinsified) produce the expected
// result and don't deviate due to double-rounding when using 80-bit FP ops.

import "dart:math";
import "package:expect/expect.dart";

main() {
  var x = 2.028240960366921e+31;
  Expect.equals(4503599627372443.0, sqrt(x));
}
