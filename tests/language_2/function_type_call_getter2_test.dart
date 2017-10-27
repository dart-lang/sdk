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
  A a = new A();
  B b = new B();
  C c = new C();

  final
      Function //# 00: compile-time error
      a2 = a;

  final
      F //# 01: compile-time error
      a3 = a;

  final
      Function //# 02: compile-time error
      b2 = b;

  final
      F //# 03: compile-time error
      b3 = b;

  final
      Function //# 04: compile-time error
      c2 = c;

  final
      F //# 05: compile-time error
      c3 = c;

  Expect.throwsTypeError(() {
    Function a4 = a as dynamic;
  });

  Expect.throwsTypeError(() {
    F a5 = a as dynamic;
  });

  Expect.throwsTypeError(() {
    Function b4 = b as dynamic;
  });

  Expect.throwsTypeError(() {
    F b5 = b as dynamic;
  });

  Expect.throwsTypeError(() {
    Function c4 = c as dynamic;
  });

  Expect.throwsTypeError(() {
    F c5 = c as dynamic;
  });
}
