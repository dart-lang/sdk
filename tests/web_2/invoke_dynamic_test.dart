// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class A {
  foo() {
    return 499;
  }

  bar(x) {
    return x + 499;
  }

  baz() {
    return 54;
  }

  titi() {
    return 123;
  }
}

class B {
  foo() {
    return 42;
  }

  bar(x) {
    return x + 42;
  }

  toto() {
    return foo() + 42;
  }
}

class C extends A {
  foo() {
    return 99;
  }

  bar(x) {
    return x + 99;
  }
}

void main() {
  var a = new A();
  Expect.equals(499, a.foo());
  Expect.equals(500, a.bar(1));
  var b = new B();
  Expect.equals(42, b.foo());
  Expect.equals(43, b.bar(1));
  var c = new C();
  Expect.equals(99, c.foo());
  Expect.equals(100, c.bar(1));

  Expect.equals(54, a.baz());
  Expect.equals(54, c.baz());

  // We don't call a.titi. This means that the compiler needs to trigger the
  // compilation of A.titi by going through the super-chain.
  Expect.equals(123, c.titi());

  Expect.equals(84, b.toto());
}
