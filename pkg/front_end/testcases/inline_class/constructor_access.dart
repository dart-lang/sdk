// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class Class {
  final int it;

  Class(this.it);

  Class.named(int it) : this.it = it + 1;
}

inline class GenericClass<T> {
  final T it;

  GenericClass(this.it);
}

main() {
  var a = new Class(3);
  var b = Class(4);
  var c = new Class.named(5);
  var d = new GenericClass<String>('foo');
  var e = GenericClass<String>('bar');
  var f = GenericClass<int>(42);
  var g = GenericClass(87);
  GenericClass<num> h = GenericClass(123);

  expect(3, a.it);
  expect(3, a);
  expect(4, b.it);
  expect(4, b);
  expect(6, c.it);
  expect(6, c);
  expect('foo', d.it);
  expect('foo', d);
  expect('bar', e.it);
  expect('bar', e);
  expect(42, f.it);
  expect(42, f);
  expect(87, g.it);
  expect(87, g);
  expect(123, h.it);
  expect(123, h);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}