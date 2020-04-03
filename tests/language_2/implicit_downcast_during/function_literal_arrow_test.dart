// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

void main() {
  Object b;
  A a = new B();
  B Function(A) f = (A a) => a;
  b = f(a); // No error
  a = new A();
  Expect.throwsTypeError(() {
    f(a);
  });
}
