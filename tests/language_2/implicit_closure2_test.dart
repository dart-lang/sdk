// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class B {
  foo(i) => 499 + i;
}

class A {
  var b;
  A() : b = new B();

  foo(i) {
    return (() => b.foo(i))();
  }
}

main() {
  var a = new A();
  Expect.equals(510, a.foo(11));
  var f = a.foo;
  Expect.equals(521, f(22));
}
