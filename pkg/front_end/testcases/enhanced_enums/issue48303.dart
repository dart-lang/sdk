// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M1 on Enum {
  int mixedInMethod1(int v) => v;
}

enum E with M1 {
  e1,
  e2,
  e3;
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected $x to be equal to $y.";
  }
}

main() {
  expectEquals(E.e1.toString(), "E.e1");
}
