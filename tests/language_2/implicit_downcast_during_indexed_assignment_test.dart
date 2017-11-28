// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C {
  void operator []=(B b, Object o) {}
}

void main() {
  A a1 = new B();
  A a2 = new A();
  C c = new C();
  c[a1] = null; // No error
  Expect.throwsTypeError(() {
    c[a2] = null;
  });
}
