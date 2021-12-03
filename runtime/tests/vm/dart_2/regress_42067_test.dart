// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--deterministic --optimization_counter_threshold=100

// Verifies correct code is generated for Float64x2.fromFloat32x4 in case of
// high register pressure.
// Regression test for https://github.com/dart-lang/sdk/issues/42067.

import 'dart:typed_data';

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
doTest(double x) {
  Float32x4 a0 = Float32x4.splat(x + 1);
  Float32x4 a1 = Float32x4.splat(x + 2);
  Float32x4 a2 = Float32x4.splat(x + 3);
  Float32x4 a3 = Float32x4.splat(x + 4);
  Float32x4 a4 = Float32x4.splat(x + 5);
  Float32x4 a5 = Float32x4.splat(x + 6);
  Float32x4 a6 = Float32x4.splat(x + 7);
  Float32x4 a7 = Float32x4.splat(x + 8);
  return Float64x2.fromFloat32x4(a0) +
      Float64x2.fromFloat32x4(a1) +
      Float64x2.fromFloat32x4(a2) +
      Float64x2.fromFloat32x4(a3) +
      Float64x2.fromFloat32x4(a4) +
      Float64x2.fromFloat32x4(a5) +
      Float64x2.fromFloat32x4(a6) +
      Float64x2.fromFloat32x4(a7) +
      Float64x2.fromFloat32x4(a0) +
      Float64x2.fromFloat32x4(a1) +
      Float64x2.fromFloat32x4(a2) +
      Float64x2.fromFloat32x4(a3) +
      Float64x2.fromFloat32x4(a4) +
      Float64x2.fromFloat32x4(a5) +
      Float64x2.fromFloat32x4(a6) +
      Float64x2.fromFloat32x4(a7);
}

void main() {
  for (int i = 0; i < 200; ++i) {
    Expect.approxEquals(88.0, doTest(1.0).x);
  }
}
