// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing closures.

import "package:expect/expect.dart";

class A {
  operator -() => this;

  foo(x) {
    -a;
    if (x) return true;
    return false;
  }

  loop1(x) {
    -a;
    while (x) return true;
    return false;
  }

  loop2(x) {
    -a;
    for (; x;) return true;
    return false;
  }

  loop3(x) {
    -a;
    var i = 0;
    do {
      if (i++ == 1) return false;
    } while (!x);
    return true;
  }
}

var a;

main() {
  a = new A();
  Expect.isTrue(a.foo(true));
  Expect.isTrue(a.loop1(true));
  Expect.isTrue(a.loop2(true));
  Expect.isTrue(a.loop3(true));
}
