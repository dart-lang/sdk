// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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

      a2 = a;

  final

      a3 = a;

  final

      b2 = b;

  final

      b3 = b;

  final

      c2 = c;

  final

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
