// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int a;
  A() : a = 42;
}

class B extends A {
  int get a => 54;
  returnSuper() => super.a;
  returnSuperInClosure() => () => super.a;
}

main() {
  B b = new B();
  Expect.equals(54, b.a);
  Expect.equals(42, b.returnSuper());
  Expect.equals(42, b.returnSuperInClosure()());
}
