// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

({Object? foo}) getN1(Object foo) => (foo: foo);

(Object?, {Object? foo}) getP1N1(x, y) => getP1N1Rec(42, x, y);

(Object?, {Object? foo}) getP1N1Rec(int n, x, y) {
  if (n == 0) return (foo: y, x);
  return getP1N1Rec(n - 1, x, y);
}

(
  dynamic,
  dynamic,
  dynamic, {
  dynamic foo,
  dynamic bar,
  dynamic baz,
}) getP3N3(int i, String s) {
  (dynamic, dynamic, {dynamic foo, dynamic qq, dynamic baz}) r1 = (
    s.substring(i, i + 1),
    s.substring(i, i + 2),
    foo: s.substring(i, i + 4),
    qq: i,
    baz: s.substring(i, i + 6)
  );
  (dynamic, dynamic, dynamic, {dynamic foo, dynamic bar, dynamic baz}) r2 = (
    r1.$1,
    r1.$2,
    s.substring(i, i + 3),
    foo: r1.foo,
    bar: s.substring(i, i + 5),
    baz: r1.baz
  );
  return r2;
}

class A {
  final int v;
  A(this.v);
  operator ==(Object other) => other is A && v == other.v;
}

main() {
  checkRecordP2(10, 20, (10, 20));
  checkRecordP3(3, 2, 1, (3, int.parse("2"), 1));
  checkRecordN1("FOO", (foo: "FOO"));

  final x = [1, 2, 3];
  checkRecordN1(x, getN1(x));

  checkRecordN2("0 1 2", "[1, 2, 3]",
      (foo: [for (int i = 0; i < 3; ++i) i].join(' '), bar: x.toString()));

  checkRecordN3(
      A(10), 1.0, 42, (foo: A(9 + int.parse("1")), bar: 1.0, baz: 40 + A(2).v));

  checkRecordP1N1(10, "abc", getP1N1(10, "abc"));

  checkRecordP1N2(A(1), A(2), A(3), (foo: A(2), A(1), bar: A(3)));

  checkRecordP3N3("h", "he", "hel", "hell", "hello", "hello,",
      [for (int i = 0; i < 3; ++i) getP3N3(i, "hello, world")][0]);
}
