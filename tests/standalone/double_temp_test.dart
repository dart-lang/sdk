// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct usage of inlined double temporary objects.

import "package:expect/expect.dart";

main() {
  for (int i = 0; i < 2000; i++) {
    testBinaryOp();
    testUnaryOp();
  }
}

// VM: temporary double should not be used as result of division,
// otherwise the function always returns the same object.
double divide(double a, double b) {
  return a / b;
}

testBinaryOp() {
  var x = divide(1.0, 2.0);
  var y = divide(2.0, 3.0);
  Expect.notEquals(x, y);
}

// VM: temporary double should be used only for "-b", otherwise the
// function would always return the same object.
double unary(double a, double b) {
  return -(a * (-b));
}

testUnaryOp() {
  var x = unary(1.0, 2.0);
  var y = unary(3.0, 4.0);
  Expect.equals(2.0, x);
  Expect.equals(12.0, y);
}
