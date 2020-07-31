// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a static type inferrer takes [noSuchMethod] into account.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

class A {
  B foobarbaz() {
    return new B();
  }
}

class B {
  noSuchMethod(im) {
    return 42;
  }
}

bar() {
  var b;
  for (int i = 0; i < 20; ++i)
    if (i % 2 == 0)
      b = new A();
    else
      b = new B();
  return b;
}

void main() {
  var x = bar();
  var y = x.foobarbaz();
  Expect.equals(42, y);
  Expect.isFalse(y is B);
}
