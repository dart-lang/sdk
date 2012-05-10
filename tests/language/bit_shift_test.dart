// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

constants() {
  Expect.equals(0, 499 >> 33);
  Expect.equals(0, (499 << 33) & 0xFFFFFFFF);
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
}

speculative() {
  var a = id(499);
  for (int i = 0; i < 1; i++) {
    Expect.equals(0, a >> 33);
    Expect.equals(0, (a << 33) & 0xFFFFFFFF);
  }
}

// JavaScript shifts by the amount modulo 32. That is x << y is equivalent to
// x << (y & 0x1F). Dart does not.
main() {
  constants();
  interceptors();
  speculative();
}
