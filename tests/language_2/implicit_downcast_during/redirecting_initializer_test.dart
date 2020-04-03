// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C {
  C(A a) : this._(a);
  C._(B b);
}

main() {
  A a1 = new B();
  A a2 = new A();
  new C(a1); // No error
  Expect.throwsTypeError(() {
    new C(a2);
  });
}
