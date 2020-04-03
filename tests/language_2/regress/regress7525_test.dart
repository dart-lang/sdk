// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Regression test for issue 7525.

foo() {
  var ol = <int>[2];
  (ol as List<int>)[0];
  int x = (ol as List<int>)[0];
  return x;
}

main() {
  for (int i = 0; i < 20; i++) {
    foo();
  }
  Expect.equals(2, foo());
}
