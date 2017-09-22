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
  foo(
      required1
     /* // //# 00: compile-time error
      ,
      {named1: 499}
     */ // //# 00: compile-time error
      ) {
    return required1;
  }

  bar(required1, required2,
      {named1: 13
      /* // //# 01: compile-time error
      ,
      named2: 17
      */ // //# 01: compile-time error
      }) {
    return required1 + required2 * 3 + named1 * 5;
  }

  gee(
      {named2: 11
      /* // //# 02: compile-time error
      ,
      named1: 31
      */ // //# 02: compile-time error
      }) {
    return named2 * 99;
  }
}

main() {
  var b = new B();
  Expect.equals(499, b.foo(499));
  Expect.equals(1 + 3 * 3 + 5 * 5, b.bar(1, 3, named1: 5));
  Expect.equals(1 + 3 * 3 + 13 * 5, b.bar(1, 3));
  Expect.equals(3 * 99, b.gee(named2: 3));
  Expect.equals(11 * 99, b.gee());
}
