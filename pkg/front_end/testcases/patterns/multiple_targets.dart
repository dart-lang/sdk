// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  final T foo;

  A(this.foo);
}

class B {
  final num foo;

  B(this.foo);
}

class C implements A<int>, B {
  final int foo;

  C(this.foo);
}

test(o) {
  switch (o) {
    case [0, 1, ...]:
      return 0;
    case [1, 2, ...]:
      return 1;
    case <int>[2, 3, ...]:
      return 2;
    case {'foo': 5}:
      return 3;
    case {'foo': 6}:
      return 4;
    case <String, int>{'foo': 7}:
      return 5;
    case A<dynamic>(foo: 5):
      return 6;
    case A<int>(foo: 6):
      return 7;
    case B(foo: 7):
      return 8;
    case (foo: 8):
      return 9;
  }
  return -1;
}

main() {
  expect(0, test([0, 1]));
  expect(0, test([0, 1, 2]));
  expect(1, test([1, 2]));
  expect(1, test([1, 2, 3]));
  expect(2, test([2, 3]));
  expect(2, test([2, 3, 4]));
  expect(-1, test(<num>[2, 3]));

  expect(3, test({'foo': 5}));
  expect(3, test({'foo': 5, 'bar': 6}));
  expect(4, test({'foo': 6}));
  expect(4, test({'foo': 6, 'bar': 7}));
  expect(5, test({'foo': 7}));
  expect(5, test({'foo': 7, 'bar': 8}));
  expect(-1, test(<String, num>{'foo': 7}));

  expect(6, test(A<num>(5)));
  expect(6, test(A<int>(5)));
  expect(-1, test(A<num>(6)));
  expect(7, test(A<int>(6)));
  expect(-1, test(A<int>(7)));
  expect(-1, test(B(5)));
  expect(-1, test(B(6)));
  expect(8, test(B(7)));
  expect(6, test(C(5)));
  expect(7, test(C(6)));
  expect(8, test(C(7)));
  expect(-1, test(C(8)));

  expect(9, test((foo: 8)));
  expect(-1, test((foo: 9)));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}