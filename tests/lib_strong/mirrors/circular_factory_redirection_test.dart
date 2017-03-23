// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "package:expect/expect.dart";

class A {
  A();
  A.circular() = B.circular; // //# 01: compile-time error
  const A.circular2() = B.circular2; // //# 02: compile-time error
}

class B {
  B();
  B.circular() = C.circular; // //# 01: continued
  const B.circular2() = C.circular2; // //# 02: continued
}

class C {
  C();
  C.circular() = A.circular; // //# 01: continued
  const C.circular2() = A.circular2; // //# 02: continued
}

main() {
  ClassMirror cm = reflectClass(A);

  new A.circular(); // //# 01: continued
  new A.circular2(); // //# 02: continued

  Expect.throws(
      () => cm.newInstance(#circular, []),
      (e) => e is NoSuchMethodError,
      'Should disallow circular redirection (non-const)');

  Expect.throws(
      () => cm.newInstance(#circular2, []),
      (e) => e is NoSuchMethodError,
      'Should disallow circular redirection (const)');
}
