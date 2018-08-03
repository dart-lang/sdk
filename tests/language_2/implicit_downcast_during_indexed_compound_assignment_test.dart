// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C {
  int operator [](A a) => 0;
  void operator []=(B b, int o) {}
}

class D {
  int operator [](B b) => 0;
  void operator []=(A a, int o) {}
}

void main() {
  A a1 = new B();
  A a2 = new A();
  C c = new C();
  D d = new D();
  c[a1] += 1; // No error
  d[a1] += 1; // No error
  Expect.throwsTypeError(() {
    c[a2] += 1;
  });
  Expect.throwsTypeError(() {
    d[a2] += 1;
  });
}
