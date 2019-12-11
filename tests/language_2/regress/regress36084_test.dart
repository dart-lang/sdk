// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  void call(int a, [int b]) {}
}

class A1 {
  void call(int a, [int b]) {}
  int noSuchMethod(Invocation invocation) {
    return 42;
  }
}

class A2 {
  // Same as A1 but without a call method.
  int noSuchMethod(Invocation invocation) {
    return 42;
  }
}

class B {
  dynamic foo;
  dynamic get bar => foo;
}

class B1 {
  dynamic foo;
  dynamic get bar => foo;

  int noSuchMethod(Invocation invocation) {
    Expect.fail('B1.noSuchMethod should not be called.');
  }
}

main() {
  B b = new B();
  b.foo = new A();
  Expect.throwsNoSuchMethodError(() => b.foo(1, 2, 3));
  Expect.throwsNoSuchMethodError(() => b.bar(1, 2, 3));
  b.foo = new A1();
  Expect.equals(42, b.foo(1, 2, 3));
  Expect.equals(42, b.bar(1, 2, 3));
  b.foo = new A2();
  Expect.equals(42, b.foo(1, 2, 3));
  Expect.equals(42, b.bar(1, 2, 3));

  // Same test but with B1, which has its own `noSuchMethod()` handler.
  B1 b1 = new B1();
  b1.foo = new A();
  Expect.throwsNoSuchMethodError(() => b1.foo(1, 2, 3));
  Expect.throwsNoSuchMethodError(() => b1.bar(1, 2, 3));
  b1.foo = new A1();
  Expect.equals(42, b1.foo(1, 2, 3));
  Expect.equals(42, b1.bar(1, 2, 3));
  b1.foo = new A2();
  Expect.equals(42, b1.foo(1, 2, 3));
  Expect.equals(42, b1.bar(1, 2, 3));
}
