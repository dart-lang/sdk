// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests optimization: transform double.toInt() to DoubleToSmi
// unless we encounter a non-Smi result, in which case we deoptimize and
// optimize it later to DoubleToInt.

import "package:expect/expect.dart";

main() {
  for (int i = 0; i < 600; i++) {
    Expect.equals(100, foo(100, 1.2));
  }
  // Deoptimize 'foo', d2smi -> d2int.
  Expect.equals(36507222016 * 2, foo(2, 36507222016.6));
  for (int i = 0; i < 600; i++) {
    Expect.equals(100, foo(100, 1.2));
  }
  Expect.equals(36507222016 * 2, foo(2, 36507222016.6));
}

foo(n, a) {
  int k = 0;
  for (int i = 0; i < n; i++) {
    k += goo(a);
  }
  return k;
}

goo(a) {
  return a.toInt();
}
