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
  var b2 = (Class.new)(4);
  var c = new Class.named(5);
  var c2 = (Class.named)(5);
  var d = new GenericClass<String>('foo');
  var d2 = (GenericClass<String>.new)('foo');
  var d3 = (GenericClass.new)<String>('foo');
  var e = GenericClass<String>('bar');
  var e2 = (GenericClass<String>.new)('bar');
  var e3 = (GenericClass.new)<String>('bar');
  var f = GenericClass<int>(42);
  var f2 = (GenericClass<int>.new)(42);
  var f3 = (GenericClass.new)<int>(42);
  var g = GenericClass(87);
  var g2 = (GenericClass.new)(87);
  GenericClass<num> h = GenericClass(123);
  GenericClass<num> h2 = (GenericClass.new)(123);

  expect(3, a.it);
  expect(3, a);
  expect(4, b.it);
  expect(4, b);
  expect(4, b2.it);
  expect(4, b2);
  expect(6, c.it);
  expect(6, c);
  expect(6, c2.it);
  expect(6, c2);
  expect('foo', d.it);
  expect('foo', d);
  expect('foo', d2.it);
  expect('foo', d2);
  expect('foo', d3.it);
  expect('foo', d3);
  expect('bar', e.it);
  expect('bar', e);
  expect('bar', e2.it);
  expect('bar', e2);
  expect('bar', e3.it);
  expect('bar', e3);
  expect(42, f.it);
  expect(42, f);
  expect(42, f2.it);
  expect(42, f2);
  expect(42, f3.it);
  expect(42, f3);
  expect(87, g.it);
  expect(87, g);
  expect(87, g2.it);
  expect(87, g2);
  expect(123, h.it);
  expect(123, h);
  expect(123, h2.it);
  expect(123, h2);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}