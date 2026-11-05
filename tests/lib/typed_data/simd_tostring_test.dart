// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The string form of the SIMD value types does not expose the lane values.
// This test pins that form so the three types stay consistent with each other
// and across backends, and so nothing starts depending on lane content leaking
// through toString.

import 'dart:typed_data';

import 'package:expect/expect.dart';

const String v128 = 'V128';

void main() {
  // Directly constructed values.
  Expect.equals(v128, Float32x4(1.0, 2.0, 3.0, 4.0).toString());
  Expect.equals(v128, Int32x4(1, 2, 3, 4).toString());
  Expect.equals(v128, Float64x2(1.0, 2.0).toString());

  // The same value types read back out of their typed lists.
  Expect.equals(v128, Float32x4List(1)[0].toString());
  Expect.equals(v128, Int32x4List(1)[0].toString());
  Expect.equals(v128, Float64x2List(1)[0].toString());

  // Interpolation goes through toString too.
  Expect.equals(v128, '${Float32x4(0.0, 0.0, 0.0, 0.0)}');
  Expect.equals(v128, '${Int32x4(0, 0, 0, 0)}');
  Expect.equals(v128, '${Float64x2(0.0, 0.0)}');

  String listOf(int n) => '[${List.filled(n, v128).join(', ')}]';

  for (final n in [0, 1, 2]) {
    Expect.equals(listOf(n), Float32x4List(n).toString());
    Expect.equals(listOf(n), Int32x4List(n).toString());
    Expect.equals(listOf(n), Float64x2List(n).toString());

    Expect.equals(
      listOf(n),
      Float32x4List.view(Float32List(n * 4).buffer).toString(),
    );
    Expect.equals(
      listOf(n),
      Int32x4List.view(Int32List(n * 4).buffer).toString(),
    );
    Expect.equals(
      listOf(n),
      Float64x2List.view(Float64List(n * 2).buffer).toString(),
    );
  }
}
