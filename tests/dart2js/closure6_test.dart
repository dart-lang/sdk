// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var foo;
  bar() => foo(3, 99);
  gee(f) => foo(fun: f);

  get foo2 => foo;
  bar2() => foo2(3, 99);
  gee2(f) => foo2(fun: f);
}

main() {
  var a = new A();
  a.foo = () => 499;
  Expect.equals(499, a.foo());
  a.foo = (x, y) => x + y;
  Expect.equals(102, a.bar());
  a.foo = ({fun: null}) => fun(41);
  Expect.equals(42, a.gee((x) => x + 1));

  a.foo = () => 499;
  Expect.equals(499, a.foo2());
  a.foo = (x, y) => x + y;
  Expect.equals(102, a.bar2());
  a.foo = ({fun: null}) => fun(41);
  Expect.equals(42, a.gee2((x) => x + 1));
}
