// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library simd_store_to_load_forward_test;

import 'dart:typed_data';
import "package:expect/expect.dart";

bool testFloat32x4TypeCheck(Float32x4 v) {
  if (v == null) {
    v = new Float32x4.zero();
  }
  var l = v * v;
  var b = v + l;
  return b is Float32x4;
}

main() {
  Float32x4List l = new Float32x4List(4);
  Float32x4 a = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var b;
  for (int i = 0; i < 8000; i++) {
    b = testFloat32x4TypeCheck(null);
  }
  Expect.equals(true, b);
}
