// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

A a1 = new B();
A a2 = new A();
B b1 = a1;
B b2 = a2;

class C {
  static B b3 = a1;
  static B b4 = a2;
  B b5 = a1;
}

class D {
  B b6 = a2;
}

void main() {
  b1; // No error
  Expect.throwsTypeError(() {
    b2;
  });
  C.b3; // No error
  Expect.throwsTypeError(() {
    C.b4;
  });
  new C(); // No error
  Expect.throwsTypeError(() {
    new D();
  });
}
