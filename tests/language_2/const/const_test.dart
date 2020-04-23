// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check const classes.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

class AConst {
  const AConst() : b_ = 3;
  final int b_;
}

class BConst {
  const BConst();
  set foo(value) {}
  get foo {
    return 5;
  }

  operator [](ix) {
    return ix;
  }

  operator []=(ix, value) {}
}

testMain() {
  var o = const AConst();
  Expect.equals(3, o.b_);

  var x = (const BConst()).foo++;
  Expect.equals(5, x);

  var y = (const BConst())[5]++;
  Expect.equals(5, y);
}

main() {
  for (int i = 0; i < 20; i++) {
    testMain();
  }
}
