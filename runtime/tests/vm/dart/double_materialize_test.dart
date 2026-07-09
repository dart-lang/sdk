// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

double f(double x, double five, dynamic y) {
  double z = x + five;
  var a = y + 5;
  return z + a.toDouble();
}

void main() {
  double x = 1.0;
  for (int i = 0; i < 1000; i++) {
    x = f(x, 5.0, i);
  }
  x = f(x, 5.0, 1.0);
  Expect.equals(509512.0, x);
}
