// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  foo() => 499;
  bar({a: 1, b: 7, c: 99}) => a + b + c;
  toto() => bar;
  gee(f) => f(toto);
}

main() {
  var a = new A();
  var foo = a.foo;
  Expect.equals(499, foo());
  var bar = a.bar;
  Expect.equals(107, bar());
  Expect.equals(3, bar(a: 1, b: 1, c: 1));
  Expect.equals(10, bar(c: 2));
  var toto = a.toto;
  var gee = a.gee;
  Expect.equals(-10, gee((f) => f()(a: -1, b: -2, c: -7)));
}
