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
  foo(required1) => required1; //# 01: compile-time error
  bar(required1, required2, {named1: 29}) => //# 02: compile-time error
      required1 + required2 * 3 + named1 * 5; //# 02: continued
  gee({named2: 11}) => named2 * 99; //# 03: compile-time error
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
  b.foo(499, named1: 88); //# 01: continued
  b.bar(1, 2, named1: 3, named2: 88); //# 02: continued
  b.bar(1, 2, named2: 88); //# 02: continued
  b.gee(named1: 3); //# 03: continued
}
