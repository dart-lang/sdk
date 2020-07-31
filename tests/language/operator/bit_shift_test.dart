// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

constants() {
  Expect.equals(0, 499 >> 33);
  Expect.equals(0, (499 << 33) & 0xFFFFFFFF);
  Expect.equals(0, (499 << 32) >> 65);
  Expect.equals(0, (499 << 32) << 65);
}

foo(i) {
  if (i != 0) {
    y--;
    foo(i - 1);
    y++;
  }
}

var y;

// id returns [x] in a way that should be difficult to predict statically.
id(x) {
  y = x;
  foo(10);
  return y;
}

interceptors() {
  Expect.equals(0, id(499) >> 33);
  Expect.equals(0, (id(499) << 33) & 0xFFFFFFFF);
  Expect.equals(0, id(499 << 32) >> 65);
  Expect.equals(0, id(499 << 32) << 65);
}

speculative() {
  var a = id(499);
  var b = id(499 << 32);
  for (int i = 0; i < 1; i++) {
    Expect.equals(0, a >> 33);
    Expect.equals(0, (a << 33) & 0xFFFFFFFF);
    Expect.equals(0, b >> 65);
    Expect.equals(0, b << 65);
  }
}

// JavaScript shifts by the amount modulo 32. That is x << y is equivalent to
// x << (y & 0x1F). Dart does not.
main() {
  for (var i = 0; i < 10; ++i) {
    constants();
    interceptors();
    speculative();
  }
}
