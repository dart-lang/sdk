// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

B f1(A a) {
  return a;
}

B f2(A a) => a;

void main() {
  Object b;
  A a = new B();
  b = f1(a); // No error
  b = f2(a); // No error
  a = new A();
  Expect.throwsTypeError(() {
    f1(a);
  });
  Expect.throwsTypeError(() {
    f2(a);
  });
}
