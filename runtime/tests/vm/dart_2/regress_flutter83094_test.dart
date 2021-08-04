// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Verifies that compiler doesn't crash due to incompatible types
// when unboxing input of a Phi.
// Regression test for https://github.com/flutter/flutter/issues/83094.

import 'package:expect/expect.dart';

class A {
  @pragma('vm:never-inline')
  double getMaxIntrinsicWidth() => 1.toDouble();
}

A _leading = A();

@pragma('vm:never-inline')
double computeMaxIntrinsicWidth(double height, double horizontalPadding) {
  final leadingWidth =
      _leading == null ? 0 : _leading.getMaxIntrinsicWidth() as int;
  return horizontalPadding + leadingWidth;
}

main() {
  Expect.throws(() => computeMaxIntrinsicWidth(1, 2));
}
