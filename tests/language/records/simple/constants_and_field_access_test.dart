// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--test_il_serialization

import "package:expect/expect.dart";

void checkRecordP2(Object? e1, Object? e2, (Object?, Object?) r) {
  Expect.equals(e1, r.$1);
  Expect.equals(e2, r.$2);
}

void checkRecordP3(Object? e1, Object? e2, Object? e3,
    (Object? e1, Object? e2, Object? e3) r) {
  Expect.equals(e1, r.$1);
  Expect.equals(e2, r.$2);
  Expect.equals(e3, r.$3);
}

void checkRecordN1(Object? foo, ({Object? foo}) r) {
  Expect.equals(foo, r.foo);
}

void checkRecordN2(Object? foo, Object? bar, ({Object? foo, Object? bar}) r) {
  Expect.equals(foo, r.foo);
  Expect.equals(bar, r.bar);
}

void checkRecordN3(Object? foo, Object? bar, Object? baz,
    ({Object? foo, Object? bar, Object? baz}) r) {
  Expect.equals(foo, r.foo);
  Expect.equals(bar, r.bar);
  Expect.equals(baz, r.baz);
}

void checkRecordP1N1(Object? e1, Object? foo, (Object?, {Object? foo}) r) {
  Expect.equals(e1, r.$1);
  Expect.equals(foo, r.foo);
}

void checkRecordP1N2(
    Object? e1,
    Object? foo,
    Object? bar,
    (
      Object? e1, {
      Object? foo,
      Object? bar,
    }) r) {
  Expect.equals(e1, r.$1);
  Expect.equals(foo, r.foo);
  Expect.equals(bar, r.bar);
}

void checkRecordP3N3(
    Object? e1,
    Object? e2,
    Object? e3,
    Object? foo,
    Object? bar,
    Object? baz,
    (Object?, Object?, Object?, {Object? foo, Object? baz, Object? bar}) r) {
  Expect.equals(bar, r.bar);
  Expect.equals(foo, r.foo);
  Expect.equals(baz, r.baz);
  Expect.equals(e1, r.$1);
  Expect.equals(e2, r.$2);
  Expect.equals(e3, r.$3);
}

(Object?, {Object? foo}) getP1N1() => getP1N1Rec(42);

(Object?, {Object? foo}) getP1N1Rec(int n) {
  if (n == 0) return const (10, foo: "abc");
  return getP1N1Rec(n - 1);
}

class A {
  final int v;
  const A(this.v);
  operator ==(Object other) => other is A && v == other.v;
}

const int two = 2;

main() {
  checkRecordP2(10, 20, const (10, 20));
  checkRecordP3(3, 2, 1, const (3, two, 1));
  checkRecordN1("FOO", const (foo: "FOO"));
  checkRecordN1(const [1, 2, 3], const (foo: [1, 2, 3]));

  checkRecordN2(
      const {1, 2, 3}, const A(20), const (foo: const {1, 2, 3}, bar: A(20)));

  checkRecordN3(A(10), 1.0, 42, const (foo: A(10), bar: 1.0, baz: 40 + 2));

  checkRecordP1N1(10, "abc", getP1N1());

  checkRecordP1N2(A(1), A(2), A(3), const (foo: A(2), A(1), bar: A(3)));

  checkRecordP3N3(
      1,
      2.0,
      'hey',
      A(10),
      const A(20),
      const ['hi'],
      const (
        2 - 1,
        2.0,
        'h' + 'ey',
        foo: A(3 + 7),
        baz: ['hi'],
        bar: A(10 * 2),
      ));
}
