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

class B {
  dynamic foo;
  dynamic get bar => foo;
}

main() {
  B b = new B();
  b.foo = new A();
  Expect.throwsNoSuchMethodError(() => b.foo(1, 2, 3));
  Expect.throwsNoSuchMethodError(() => b.bar(1, 2, 3));
  b.foo = new A1();
  Expect.equals(42, b.foo(1, 2, 3));
  Expect.equals(42, b.bar(1, 2, 3));
}
