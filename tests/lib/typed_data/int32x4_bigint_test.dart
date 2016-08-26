// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library int32x4_bigint_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

main() {
  var n = 18446744073709551617;
  var x = new Int32x4(n, 0, 0, 0);
  Expect.equals(x.x, 1);
}
