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
  Expect.throwsTypeError(() => c as BToB); //# 01: ok
  Expect.throwsTypeError(() => c as NullToObject); //# 02: ok
  Expect.throwsTypeError(() => c as Function); //# 03: ok

  // The same goes for class `D`: `implements Function` is ignored in Dart 2.
  D d = new D();
  Expect.throwsTypeError(() => d as BToB); //# 04: ok
  Expect.throwsTypeError(() => d as NullToObject); //# 05: ok
  Expect.throwsTypeError(() => d as Function); //# 06: ok
}
