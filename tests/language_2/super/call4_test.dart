// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  bool foo();
  bool bar(int a);
  bool baz({int b});
  bool boz(int a, {int c});

  bool noSuchMethod(Invocation im) => true;
}

class D extends C {
  bool noSuchMethod(Invocation im) => false;

  // `super.foo()` et al. will statically use [C]'s [noSuchMethod] forwarder,
  // but the forwarder will (virtually) call [D]'s [noSuchMethod] at runtime.

  test1() {
    return super.foo();
  }

  test2() {
    return super.bar(1);
  }

  test3() {
    return super.baz(b: 2);
  }

  test4() {
    return super.boz(1, c: 2);
  }
}

main() {
  var d = new D();
  Expect.isFalse(d.test1());
  Expect.isFalse(d.test2());
  Expect.isFalse(d.test3());
  Expect.isFalse(d.test4());
}
