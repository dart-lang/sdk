// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class M1();

mixin class const M2();

mixin class M3() {
  final int id = 0;
  this;
}

class C1 = Object with M1;
class C2 = Object with M2;
class C3 = Object with M3;

mixin class M4(int x) {
  final int id = x;
}

class C4 = Object with M4;

main() {
  var m1 = M1();
  var m2 = const M2();
  expect(0, M3().id);
  var c1 = C1();
  var c2 = C2();
  expect(0, C3().id);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
