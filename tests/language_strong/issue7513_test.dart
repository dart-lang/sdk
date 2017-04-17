// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

// Regression test for issue 7513.

foo(a, b) {
  b[0] = 0.1;
  return a * b[0];
}

main() {
  var a = 0.1;
  var b = [0.1];
  for (var i = 0; i < 20; i++) {
    foo(a, b);
  }
  Expect.approxEquals(0.01, foo(a, b));
}
