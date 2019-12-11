// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

import "package:expect/expect.dart";

class B {}

class C {
  B call(B b) => b;
}

class D implements Function {
  B call(B b) => b;
}

typedef B BToB(B x);

typedef Object NullToObject(Null x);

main() {
  // The presence of a `.call` method does not cause class `C` to become a
  // subtype of any function type.
  C c = new C();
  Expect.isFalse(c is BToB); //# 01: ok
  Expect.isFalse(c is NullToObject); //# 02: ok
  Expect.isFalse(c is Function); //# 03: ok

  // The same goes for class `D`: `implements Function` is ignored in Dart 2.
  D d = new D();
  Expect.isFalse(d is BToB); //# 04: ok
  Expect.isFalse(d is NullToObject); //# 05: ok
  Expect.isFalse(d is Function); //# 06: ok
}
