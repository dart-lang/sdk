// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that pair locations are remaped in slow path environments.
// VMOptions=--optimization_counter_threshold=10 --no-use-osr --no-background_compilation

import "package:expect/expect.dart";

class A {
  final f;
  A(this.f);
}

foo(i) {
  int j = 0x7fffffffffffffff + i;
  var c = new A(j); // allocation will be sunk
  var r = 0;
  for (var k = 0; k < 10; k++) {
    if ((j & (1 << k)) != 0) {
      r++;
    }
  }
  return c.f - r;
}

main() {
  for (var i = 0; i < 1000; i++) {
    Expect.equals(0x7fffffffffffffff - 10, foo(0));
  }
}
