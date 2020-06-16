// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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

      ,
      {named1: 499}

      ) {
    return required1;
  }

  bar(required1, required2,
      {named1: 13

      ,
      named2: 17

      }) {
    return required1 + required2 * 3 + named1 * 5;
  }

  gee(
      {named2: 11

      ,
      named1: 31

      }) {
    return named2 * 99;
  }
}

main() {
  // Ensure that compile-time errors are reached.
  var b = new B();
  b.foo(499);
  b.bar(1, 3, named1: 5);
  b.gee(named2: 3);
}
