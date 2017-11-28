// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test num.clamp.

import "package:expect/expect.dart";

testIntClamp() {
  Expect.equals(2, 2.clamp(1, 3));
  Expect.equals(1, 0.clamp(1, 3));
  Expect.equals(3, 4.clamp(1, 3));
  Expect.equals(-2, (-2).clamp(-3, -1));
  Expect.equals(-1, 0.clamp(-3, -1));
  Expect.equals(-3, (-4).clamp(-3, -1));
  Expect.equals(0, 1.clamp(0, 0));
  Expect.equals(0, (-1).clamp(0, 0));
  Expect.equals(0, 0.clamp(0, 0));
  Expect.throwsArgumentError(() => 0.clamp(0, -1));
}

testDoubleClamp() {
  Expect.equals(2.0, 2.clamp(1.0, 3.0));
  Expect.equals(1.0, 0.clamp(1.0, 3.0));
  Expect.equals(3.0, 4.clamp(1.0, 3.0));
  Expect.equals(-2.0, (-2.0).clamp(-3.0, -1.0));
  Expect.equals(-1.0, 0.0.clamp(-3.0, -1.0));
  Expect.equals(-3.0, (-4.0).clamp(-3.0, -1.0));
  Expect.equals(0.0, 1.0.clamp(0.0, 0.0));
  Expect.equals(0.0, (-1.0).clamp(0.0, 0.0));
  Expect.equals(0.0, 0.0.clamp(0.0, 0.0));
  Expect.throwsArgumentError(() => 0.0.clamp(0.0, -1.0));
}

testDoubleClampInt() {
  Expect.equals(2.0, 2.0.clamp(1, 3));
  Expect.equals(1, 0.0.clamp(1, 3));
  Expect.isTrue(0.0.clamp(1, 3) is int);
  Expect.equals(3, 4.0.clamp(1, 3));
  Expect.isTrue(4.0.clamp(1, 3) is int);
  Expect.equals(-2.0, (-2.0).clamp(-3, -1));
  Expect.equals(-1, 0.0.clamp(-3, -1));
  Expect.isTrue(0.0.clamp(-3, -1) is int);
  Expect.equals(-3, (-4.0).clamp(-3, -1));
  Expect.isTrue((-4.0).clamp(-3, -1) is int);
  Expect.equals(0, 1.0.clamp(0, 0));
  Expect.isTrue(1.0.clamp(0, 0) is int);
  Expect.equals(0, (-1.0).clamp(0, 0));
  Expect.isTrue((-1.0).clamp(0, 0) is int);
  Expect.equals(0.0, 0.0.clamp(0, 0));
  Expect.isTrue(0.0.clamp(0, 0) is double);
  Expect.throwsArgumentError(() => 0.0.clamp(0, -1));
}

testDoubleClampExtremes() {
  Expect.equals(2.0, 2.0.clamp(-double.infinity, double.infinity));
  Expect.equals(2.0, 2.0.clamp(-double.infinity, double.nan));
  Expect.equals(double.infinity, 2.0.clamp(double.infinity, double.nan));
  Expect.isTrue(2.0.clamp(double.nan, double.nan).isNaN);
  Expect.throwsArgumentError(() => 0.0.clamp(double.nan, double.infinity));
}

main() {
  testIntClamp();
  testDoubleClamp();
  testDoubleClampInt();
  testDoubleClampExtremes();
}
