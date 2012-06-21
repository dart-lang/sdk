// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var foo;
bar() => foo(3, 99);
gee(f) => foo(fun: f);

get foo2() => foo;
bar2() => foo2(3, 99);
gee2(f) => foo2(fun: f);

globalTest() {
  foo = () => 499;
  Expect.equals(499, foo());
  foo = (x, y) => x + y;
  Expect.equals(102, bar());
  foo = ([fun = null]) => fun(41);
  Expect.equals(42, gee((x) => x + 1));

  foo = () => 499;
  Expect.equals(499, foo2());
  foo = (x, y) => x + y;
  Expect.equals(102, bar2());
  foo = ([fun = null]) => fun(41);
  Expect.equals(42, gee2((x) => x + 1));
}

class A {
  static var foo;
  static bar() => foo(3, 99);
  static gee(f) => foo(fun: f);

  static get foo2() => foo;
  static bar2() => foo2(3, 99);
  static gee2(f) => foo2(fun: f);
}

staticTest() {
  A.foo = () => 499;
  Expect.equals(499, A.foo());
  A.foo = (x, y) => x + y;
  Expect.equals(102, A.bar());
  A.foo = ([fun = null]) => fun(41);
  Expect.equals(42, A.gee((x) => x + 1));

  A.foo = () => 499;
  Expect.equals(499, A.foo2());
  A.foo = (x, y) => x + y;
  Expect.equals(102, A.bar2());
  A.foo = ([fun = null]) => fun(41);
  Expect.equals(42, A.gee2((x) => x + 1));
}

main() {
  globalTest();
  staticTest();
}