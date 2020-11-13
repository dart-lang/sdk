// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Superclass {
  String method1(num argument1, num argument2) => "Superclass";
  String method2(num argument1, num argument2) => "Superclass";
  String method3(num argument1, covariant int argument2) => "Superclass";
  String method4(num argument1, covariant num argument2) => "Superclass";
}

class Mixin {
  String method1(num argument1, num argument2) => "Mixin";
  String method2(covariant int argument1, num argument2) => "Mixin";
  String method3(num argument1, num argument2) => "Mixin";
  String method4(covariant int argument1, int argument2) => "Mixin";
}

class Class extends Superclass with Mixin {}

main() {
  Class c = new Class();
  expect("Mixin", c.method1(0, 1));
  expect("Mixin", c.method2(0, 1));
  expect("Mixin", c.method3(0, 1));
  expect("Mixin", c.method4(0, 1));

  Superclass s = c;
  expect("Mixin", s.method1(0.5, 1.5));
  throws(() => s.method2(0.5, 1.5));
  expect("Mixin", s.method3(0.5, 1));
  throws(() => s.method4(0.5, 1));
  expect("Mixin", s.method4(1, 0.5));

  Mixin m = c;
  expect("Mixin", m.method1(0, 1));
  expect("Mixin", m.method2(0, 1));
  expect("Mixin", m.method3(0, 1));
  expect("Mixin", m.method4(0, 1));
}

void expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

void throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Expected exception';
}
