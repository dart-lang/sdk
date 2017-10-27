// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final call = null;
}

class B {
  get call => null;
}

class C {
  set call(x) {}
}

typedef int F(String str);

main() {
  Expect.isFalse(new A() is Function);
  Expect.isFalse(new B() is Function);
  Expect.isFalse(new C() is Function);
  Expect.isFalse(new A() is F);
  Expect.isFalse(new B() is F);
  Expect.isFalse(new C() is F);
}
