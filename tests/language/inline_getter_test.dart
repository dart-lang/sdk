// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test inlining of instance getters.
// Three classes access always the same field. Optimize method foo and inline
// getter for classes 'A' and 'B'. Call later via 'C' and cause deoptimization.

class A {
  int f;
  A(this.f) {}
  int foo() {
    return f;  // <-- inline getter for classes 'A' and 'B'.
  }
}

class B extends A {
  B() : super(2) {}
}

class C extends A {
  C() : super(10) {}
}

class InlineGetterTest {
  static testMain() {
    var a = new A(1);
    var b = new B();
    int sum = 0;
    for (int i = 0; i < 5000; i++) {
      sum += a.foo();
      sum += b.foo();
    }
    var c = new C();
    sum += c.foo();  // <-- Deoptimizing.
    Expect.equals(15010, sum);
  }
}

main() {
  InlineGetterTest.testMain();
}
