// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for overflow (wrap-around) during computations in range analysis.

import "package:expect/expect.dart";

@pragma('vm:never-inline')
int foofoo(int b) {
  for (int i = 0x7ffffffffffffffc; i <= b; i += 2) {
    if (i < 0) {
      return i - 0x4000000000000000;
    }
  }
  return 0;
}

main() {
  for (var i = 0; i < 10000; i++) {
    foofoo(0x7fffffffffffffff);
  }
  Expect.equals(foofoo(0x7fffffffffffffff), 4611686018427387904);
}
