// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no-background-compilation --optimization-counter-threshold=100

// Verify that runtime correctly materializes unboxed variables on the catch
// entry in optimized code.

import 'dart:typed_data';

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
void testThrow(bool shouldThrow) {
  var dbl = 0.0;
  var i32 = 0;
  var i64 = 0;
  var f32x4 = new Float32x4.zero();
  var f64x2 = new Float64x2.zero();
  var i32x4 = new Int32x4(0, 0, 0, 0);
  try {
    for (var i = 0; i < 100; i++) {
      dbl += i;
      i32 = i | 0x70000000;
      i64 = i | 0x80000000;
      final d = i.toDouble();
      f32x4 += new Float32x4(d, -d, d, -d);
      f64x2 += new Float64x2(d, -d);
      i32x4 += new Int32x4(-i, i, -i, i);
      if (shouldThrow && i == 50) {
        throw "";
      }
    }
  } catch (e) {}

  if (shouldThrow) {
    Expect.equals(1275.0, dbl);
    Expect.equals(0x70000000 | 50, i32);
    Expect.equals(0x80000000 | 50, i64);
    Expect.listEquals([1275.0, -1275.0, 1275.0, -1275.0],
        [f32x4.x, f32x4.y, f32x4.z, f32x4.w]);
    Expect.listEquals([1275.0, -1275.0], [f64x2.x, f64x2.y]);
    Expect.listEquals(
        [-1275, 1275, -1275, 1275], [i32x4.x, i32x4.y, i32x4.z, i32x4.w]);
  }
}

void main() {
  for (var i = 0; i < 100; i++) testThrow(false);
  testThrow(true);
}
