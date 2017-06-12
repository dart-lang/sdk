// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: "lib")
import "dart:mirrors";
import "package:expect/expect.dart";

class A {
  A();
  factory A.circular() = B.circular;
  const factory A.circular2() = B.circular2;
}

class B implements A {
  B();
  factory B.circular() = C.circular;
  const factory B.circular2() = C.circular2;
}

class C implements B {
  const C();
  factory C.circular()
  /* //# 01: compile-time error
       = C;
  */ = A.circular; //# 01: continued

  const factory C.circular2()
  /* //# 02: compile-time error
       = C;
  */ = A.circular2; //# 02: continued
}

main() {
  ClassMirror cm = reflectClass(A);

  new A.circular();
  new A.circular2();
}
