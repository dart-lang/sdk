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

  if (!dart2jsProductionMode) {
    Expect.throwsTypeError(() {
      Function a1 = a as dynamic;
    });

    Expect.throwsTypeError(() {
      F a2 = a as dynamic;
    });

    Expect.throwsTypeError(() {
      Function b1 = b as dynamic;
    });

    Expect.throwsTypeError(() {
      F b2 = b as dynamic;
    });

    Expect.throwsTypeError(() {
      Function c1 = c as dynamic;
    });

    Expect.throwsTypeError(() {
      F c2 = c as dynamic;
    });
  }
}
