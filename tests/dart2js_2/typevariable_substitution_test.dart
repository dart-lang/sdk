// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test to ensure that we substitute type variables in is-tests.

import "package:expect/expect.dart";

class A<T> {
  A.foo(o) {
    Expect.isTrue(o is A<T>);
  }
  A();
}

class B extends A<int> {
  B.foo(o) : super.foo(o);
}

main() => new B.foo(new A<int>());
