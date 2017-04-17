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
  var b = new B();
  Expect.throws(() => b.foo(499, named1: 88), (e) => e is NoSuchMethodError);
  Expect.throws(
      () => b.bar(1, 2, named1: 3, named2: 88), (e) => e is NoSuchMethodError);
  Expect.throws(() => b.bar(1, 2, named2: 88), (e) => e is NoSuchMethodError);
  Expect.throws(() => b.gee(named1: 3), (e) => e is NoSuchMethodError);
}
