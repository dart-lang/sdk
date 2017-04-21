// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import "package:expect/expect.dart";

class A {
  A() {}
  factory A.foo() = C.bar;
  int m() {}
}

class C extends A {
  C() {}
  factory C.bar() = D;
  int m() { return 1; }
}

class D extends C {
  int m() { return 2; }
}

main() {
  A a = new A.foo();
  Expect.equals(2, a.m());
}
