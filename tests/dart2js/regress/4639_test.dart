// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  bool contains(x, y) => true;
}

class B {
  A makeA() => new A();
  bool test() => makeA().contains(1, 2);
}

main() {
  Expect.isTrue(new B().test());
  Expect.isTrue("x".contains("x"));
}
