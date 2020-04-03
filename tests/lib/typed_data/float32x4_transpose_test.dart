// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library float32x4_transpose_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

void transpose(Float32x4List m) {
  Expect.equals(4, m.length);
  var m0 = m[0];
  var m1 = m[1];
  var m2 = m[2];
  var m3 = m[3];

  var t0 = m0.shuffleMix(m1, Float32x4.xyxy);
  var t1 = m2.shuffleMix(m3, Float32x4.xyxy);
  m[0] = t0.shuffleMix(t1, Float32x4.xzxz);
  m[1] = t0.shuffleMix(t1, Float32x4.ywyw);

  var t2 = m0.shuffleMix(m1, Float32x4.zwzw);
  var t3 = m2.shuffleMix(m3, Float32x4.zwzw);
  m[2] = t2.shuffleMix(t3, Float32x4.xzxz);
  m[3] = t2.shuffleMix(t3, Float32x4.ywyw);
}

void testTranspose(Float32x4List m, Float32x4List r) {
  transpose(m); // In place transpose.
  for (int i = 0; i < 4; i++) {
    var a = m[i];
    var b = r[i];
    Expect.equals(b.x, a.x);
    Expect.equals(b.y, a.y);
    Expect.equals(b.z, a.z);
    Expect.equals(b.w, a.w);
  }
}

main() {
  var A = new Float32x4List(4);
  A[0] = new Float32x4(1.0, 2.0, 3.0, 4.0);
  A[1] = new Float32x4(5.0, 6.0, 7.0, 8.0);
  A[2] = new Float32x4(9.0, 10.0, 11.0, 12.0);
  A[3] = new Float32x4(13.0, 14.0, 15.0, 16.0);
  var B = new Float32x4List(4);
  B[0] = new Float32x4(1.0, 5.0, 9.0, 13.0);
  B[1] = new Float32x4(2.0, 6.0, 10.0, 14.0);
  B[2] = new Float32x4(3.0, 7.0, 11.0, 15.0);
  B[3] = new Float32x4(4.0, 8.0, 12.0, 16.0);
  var I = new Float32x4List(4);
  I[0] = new Float32x4(1.0, 0.0, 0.0, 0.0);
  I[1] = new Float32x4(0.0, 1.0, 0.0, 0.0);
  I[2] = new Float32x4(0.0, 0.0, 1.0, 0.0);
  I[3] = new Float32x4(0.0, 0.0, 0.0, 1.0);
  for (int i = 0; i < 20; i++) {
    var m = new Float32x4List.fromList(I);
    testTranspose(m, I);
    m = new Float32x4List.fromList(A);
    testTranspose(m, B);
  }
}
