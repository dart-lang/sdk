// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C {
  static void f(B b) {}
}

main() {
  A a1 = new B();
  A a2 = new A();
  C.f(a1); // No error
  Expect.throwsTypeError(() {
    C.f(a2);
  });
}
