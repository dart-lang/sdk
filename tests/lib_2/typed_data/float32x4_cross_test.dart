// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library float32x4_cross_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

Float32x4 cross(Float32x4 a, Float32x4 b) {
  var t0 = a.shuffle(Float32x4.YZXW);
  var t1 = b.shuffle(Float32x4.ZXYW);
  var l = t0 * t1;
  t0 = a.shuffle(Float32x4.ZXYW);
  t1 = b.shuffle(Float32x4.YZXW);
  var r = t0 * t1;
  return l - r;
}

void testCross(Float32x4 a, Float32x4 b, Float32x4 r) {
  var x = cross(a, b);
  Expect.equals(r.x, x.x);
  Expect.equals(r.y, x.y);
  Expect.equals(r.z, x.z);
  Expect.equals(r.w, x.w);
}

main() {
  var x = new Float32x4(1.0, 0.0, 0.0, 0.0);
  var y = new Float32x4(0.0, 1.0, 0.0, 0.0);
  var z = new Float32x4(0.0, 0.0, 1.0, 0.0);
  var zero = new Float32x4.zero();

  for (int i = 0; i < 20; i++) {
    testCross(x, y, z);
    testCross(z, x, y);
    testCross(y, z, x);
    testCross(z, y, -x);
    testCross(x, z, -y);
    testCross(y, x, -z);
    testCross(x, x, zero);
    testCross(y, y, zero);
    testCross(z, z, zero);
    testCross(x, y, cross(-y, x));
    testCross(x, y + z, cross(x, y) + cross(x, z));
  }
}
