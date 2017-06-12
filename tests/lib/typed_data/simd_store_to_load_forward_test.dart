// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library simd_store_to_load_forward_test;

import 'dart:typed_data';
import "package:expect/expect.dart";

Float32x4 testLoadStoreForwardingFloat32x4(Float32x4List l, Float32x4 v) {
  l[1] = v;
  var r = l[1];
  return r;
}

main() {
  Float32x4List l = new Float32x4List(4);
  Float32x4 a = new Float32x4(1.0, 2.0, 3.0, 4.0);
  Float32x4 b;
  for (int i = 0; i < 20; i++) {
    b = testLoadStoreForwardingFloat32x4(l, a);
  }
  Expect.equals(a.x, b.x);
  Expect.equals(a.y, b.y);
  Expect.equals(a.z, b.z);
  Expect.equals(a.w, b.w);
}
