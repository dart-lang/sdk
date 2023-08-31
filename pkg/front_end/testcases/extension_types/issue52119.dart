// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Foo._(int i) {
  Foo(int i) : this._(i + 2);

  Foo.redirectNamed1(int a, int b) : this.named(a, subtract: b);
  Foo.redirectNamed2(int a, int b) : this.named(subtract: b, a);
  Foo.named(int value, {required int subtract}) : i = value - subtract;

  Foo.erroneous() : this.unresolved(); // Error
}

extension type Bar<T>._(this.i) {
  Bar(T i) : this._(i);
}

main() {
  expect(44, Foo(42).i);
  expect(42, Foo._(42).i);
  expect(3, Foo.redirectNamed1(5, 2).i);
  expect(5, Foo.redirectNamed2(7, 2).i);
  expect(5, Bar(5).i);
  expect("foo", Bar("foo").i);
  expect(5, Bar._(5).i);
  expect("foo", Bar._("foo").i);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
