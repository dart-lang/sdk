// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'issue31767_lib.dart';

StringBuffer sb;

class C {
  final int w;
  C.foo(int x, [int y = 0, int z = 0]) : w = p("x", x) + p("y", y) + p("z", z);
}

int p(String name, int value) {
  sb.write("$name = $value, ");
  return value;
}

mixin M on C {
  int get w2 => w * w;
}

class D = C with M;

mixin N on A {
  int get w2 => w * w;
}

class E = A with N;

main() {
  sb = new StringBuffer();
  var a = A.foo(1, 2);
  expect('x = 1, y = 2, z = 3, ', sb.toString());
  expect(6, a.w);
  expect(5, a.a.field);

  sb = new StringBuffer();
  var c = C.foo(1, 2);
  expect('x = 1, y = 2, z = 0, ', sb.toString());
  expect(3, c.w);

  sb = new StringBuffer();
  var d = D.foo(1, 2);
  expect('x = 1, y = 2, z = 0, ', sb.toString());
  expect(3, d.w);
  expect(9, d.w2);

  sb = new StringBuffer();
  var e = E.foo(1, 2);
  expect('x = 1, y = 2, z = 3, ', sb.toString());
  expect(6, e.w);
  expect(36, e.w2);
  expect(5, e.a.field);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
