// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class A {
  int _x = 42;
}

abstract class B extends A {}

class C extends B {
  C() {}
}

main() {
  // Regression test for https://github.com/dart-lang/sdk/issues/27421
  Expect.equals(new C()._x, 42);
}
