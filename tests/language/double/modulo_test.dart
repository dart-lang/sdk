// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test optimization of modulo operator on Double.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

main() {
  double k = -0.33333;
  double firstResPos = doMod(k, 1.0);
  double firstResNeg = doMod(k, -1.0);
  for (int i = 0; i < 20; i++) {
    Expect.equals(firstResPos, doMod(k, 1.0));
    Expect.equals(firstResNeg, doMod(k, -1.0));
  }
}

doMod(a, b) => a % b;
