// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var a;

main() {
  // Write a loop to force a bailout method on [A.foo].
  for (int i = 0; i < 10; i++) {
    if (a != null) new A().foo([]);
    Expect.equals(42, new A().foo(new A()));
  }
}

class A {
  // In dart2js, the optimized version of foo tries to optimize the
  // uses of a.length (which is used two times here: for the index,
  // and for the bounds check), and that optmization used to crash
  // the compiler.
  foo(a) => a[a.length];

  int get length => 42;
  operator [](index) => 42;
}
