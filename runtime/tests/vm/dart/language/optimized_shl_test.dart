// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

// Test truncating left-shift that can deoptimize.
// Regression test for issue 19330.

test_shl(w, x) {
  x += 1;
  return w << x & 0xff;
}

main() {
  for (var i = 0; i < 20; i++) test_shl(i, i % 10);
  Expect.equals(4, test_shl(1, 1));
}
