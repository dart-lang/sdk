// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests elimination of null checks.
// This test requires non-nullable experiment.

// @dart = 2.10

class A {
  String? nonNullable;
  String? nullable;
  String? alwaysNull;
  A({this.nonNullable, this.nullable, this.alwaysNull});
}

testNonNullable(A a) => a.nonNullable!;
testNullable(A a) => a.nullable!;
testAlwaysNull(A a) => a.alwaysNull!;

unused() => A(nonNullable: null, alwaysNull: 'abc');

A staticField = A(nonNullable: 'hi', nullable: 'bye');

void main() {
  final list = [
    A(nonNullable: 'foo', nullable: null, alwaysNull: null),
    staticField,
  ];
  for (A a in list) {
    testNonNullable(a);
    testNullable(a);
    testAlwaysNull(a);
  }
}
