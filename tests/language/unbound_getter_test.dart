// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Verify that an unbound getter is properly resolved at runtime.

class A {
  const A();
  foo() {
    return y;
  }
}

class B extends A {
  final y;
  const B(val)
      : super(),
        y = val;
}

class UnboundGetterTest {
  static testMain() {
    var b = new B(1);
    print(b.foo());
  }
}

main() {
  UnboundGetterTest.testMain();
}
