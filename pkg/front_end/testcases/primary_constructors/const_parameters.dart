// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0 {
  final int a;
  final int b;
  const new(int c, dynamic d) : a = d.length, b = c;
}

class const C1(int c, dynamic d) {
  final int a = d.length;
  final int b = c;
}

class const C2(int c, dynamic d) {
  final int a;
  final int b;

  this : a = d.length, b = c;
}

class const C3(int c, dynamic d) {
  final int a = d.length;
  final int b;

  this : b = c;
}

class const C4(int c, dynamic d) {
  final int a = d.length;
  final int b = c;

  this : a = d.length, b = c;
}

class const C5(int c, dynamic d) {
  int a = d.length;
  int b = c;
  int? _;
}

class const C6(int c, dynamic d) {
  var a = d.length;
  var b = c;
  var _;
}

main() {
  const a = C0(0, '1234');
  expect(4, a.a);
  expect(0, a.b);

  const b = C1(1, '12345');
  expect(5, b.a);
  expect(1, b.b);

  const c = C2(2, '123456');
  expect(6, c.a);
  expect(2, c.b);

  const d = C3(3, '1234567');
  expect(7, d.a);
  expect(3, d.b);
}

test() {
  const e = C4(0, '');
  const f = C5(0, '');
  const g = C6(0, '');
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
