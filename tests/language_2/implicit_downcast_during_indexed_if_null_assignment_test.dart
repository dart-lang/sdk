// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C {
  Object operator [](A a) => 0;
  void operator []=(B b, Object o) {}
}

class D {
  Object operator [](B b) => 0;
  void operator []=(A a, Object o) {}
}

class E {
  Object operator [](A a) => null;
  void operator []=(B b, Object o) {}
}

void main() {
  A a1 = new B();
  A a2 = new A();
  C c = new C();
  D d = new D();
  E e = new E();
  c[a1] ??= 1; // No error
  d[a1] ??= 1; // No error
  e[a1] ??= 1; // No error
  c[a2] ??= 1; // No error - []= skipped
  Expect.throwsTypeError(() {
    d[a2] ??= 1;
  });
  Expect.throwsTypeError(() {
    e[a2] ??= 1;
  });
}
