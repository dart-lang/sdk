// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  foo(required1, {named1: 499}) => -(required1 + named1 * 3);
  bar(required1, required2, {named1: 13, named2: 17}) =>
      -(required1 + required2 * 3 + named1 * 5 + named2 * 7);
  gee({named1: 31}) => -named1;
}

class B extends A {
  foo(required1) => required1;
  bar(required1, required2, {named1: 29}) =>
      required1 + required2 * 3 + named1 * 5;
  gee({named2: 11}) => named2 * 99;
}

main() {
  // Invoke all A methods so that they are registered.
  var a = new A();
  Expect.equals(
      -2092,
      a.foo(499, named1: 88) +
          a.bar(1, 2, named1: 3, named2: 88) +
          a.bar(1, 2, named2: 88) +
          a.gee(named1: 3));
  var b = new B();
  Expect.equals(499, b.foo(499));
  Expect.equals(1 + 3 * 3 + 5 * 5, b.bar(1, 3, named1: 5));
  Expect.equals(1 + 3 * 3 + 29 * 5, b.bar(1, 3));
  Expect.equals(3 * 99, b.gee(named2: 3));
  Expect.equals(11 * 99, b.gee());
}
