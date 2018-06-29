// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  foo([a]) {
    return a;
  }

  bar(a, [b]) {
    return b;
  }

  noSuchMethod(mirror) {
    return 0;
  }
}

main() {
  A a = new A();
  Expect.equals(42, a.foo(42));
  Expect.equals(null, a.foo());
  Expect.equals(null, a.bar(42));
  Expect.equals(42, a.bar(null, 42));
  Expect.equals(0, (a as dynamic).foo(1, 2));
  Expect.equals(0, (a as dynamic).bar());
  Expect.equals(0, (a as dynamic).bar(1, 2, 3));
}
