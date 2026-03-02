// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1(final int _);

class C2(var int _);

class C3(final int _, final int _); // Error

class C4(int _, int _); // Ok

class C5(var int _) {
  int x = _; // Error

  this : assert(_ > 0); // Error
}

extension type ET1(int _);

extension type ET2(final int _);

extension type ET3(int _) {
  this : assert(_ > 0); // Error
}

main() {
  var c1 = C1(0);
  expect(0, c1._);

  var c2 = C2(1);
  expect(1, c2._);
  c2._ = 2;
  expect(2, c2._);

  C4(0, 0);

  var et1 = ET1(0);
  expect(0, et1._);

  var et2 = ET2(1);
  expect(1, et2._);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}