// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests elimination of null tests.

class A {
  String nonNullable;
  String nullable;
  String alwaysNull;
  A({this.nonNullable, this.nullable, this.alwaysNull});
}

testNonNullableIf1(A a) {
  if (a.nonNullable == null) {
    print('null');
  }
}

testNullableIf1(A a) {
  if (a.nullable == null) {
    print('null');
  }
}

testAlwaysNullIf1(A a) {
  if (a.alwaysNull == null) {
    print('null');
  }
}

testNonNullableIf2(A a) {
  if (a.nonNullable != null && someCondition()) {
    print('not null');
  }
}

testNullableIf2(A a) {
  if (a.nullable != null && someCondition()) {
    print('not null');
  }
}

testAlwaysNullIf2(A a) {
  if (a.alwaysNull != null && someCondition()) {
    print('not null');
  }
}

testNonNullableCondExpr(A a) => a.nonNullable != null ? 'not null' : 'null';
testNullableCondExpr(A a) => a.nullable != null ? 'not null' : 'null';
testAlwaysNullCondExpr(A a) => a.alwaysNull != null ? 'not null' : 'null';

someCondition() => int.parse("1") == 1;
unused() => A(nonNullable: null, alwaysNull: 'abc');

A staticField = A(nonNullable: 'hi', nullable: 'bye');

void main() {
  final list = [
    A(nonNullable: 'foo', nullable: null, alwaysNull: null),
    staticField,
  ];
  for (A a in list) {
    testNonNullableIf1(a);
    testNullableIf1(a);
    testAlwaysNullIf1(a);
    testNonNullableIf2(a);
    testNullableIf2(a);
    testAlwaysNullIf2(a);
    testNonNullableCondExpr(a);
    testNullableCondExpr(a);
    testAlwaysNullCondExpr(a);
  }
}
