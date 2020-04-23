// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Tester<T> {
  testGenericType(x) {
    return x is T;
  }
}

abstract class A = B with C;

class B {}

class C {}

class X extends Y with Z {}

class Y {}

class Z {}

main() {
  // Classes A and X are only used as generic arguments.
  Expect.isFalse(new Tester<A>().testGenericType(new Object()));
  Expect.isFalse(new Tester<X>().testGenericType(new Object()));
}
