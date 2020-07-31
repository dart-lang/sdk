// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Proper nullable comparison (dartbug.com/35325).
//
// VMOptions=--deterministic --optimization_counter_threshold=10

import "package:expect/expect.dart";

late bool var1;
late int var2;

bar(List<int> par1, double par2) {
  if (par2 == 123.0) return 456.0;
  // fall into return null
}

bool foo(double par1) {
  return (bar(
          [81, 17],
          ((!(var1))
              ? double.maxFinite
              : (var1 ? (80).floorToDouble() : par1))) ==
      (((~(var2))).roundToDouble()).sign);
}

void main() {
  for (int i = 0; i < 20; ++i) {
    var1 = true;
    var2 = 4;
    var x = foo(0.0);
    Expect.isFalse(x);
    Expect.isTrue(var1);
    Expect.equals(4, var2);
  }
}
