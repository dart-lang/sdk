// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

// Test correct register allocation with a value used twice at the same
// instruction.
test(List a, int v) {
  a[v] = v;
}

main() {
  var list = new List(2);
  for (var i = 0; i < 20; i++) test(list, 1);
  Expect.equals(null, list[0]);
  Expect.equals(1, list[1]);
}
