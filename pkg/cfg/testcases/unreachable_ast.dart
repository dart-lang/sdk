// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: dead_code

class A {
  int foo(int a, int b, int c) => a + b + c;
}

void bar(int a, int b, int c) {}

void unreachable1(A obj) {
  obj.foo(10, (throw 'Bye'), int.parse('11'));
  print(1);
}

void unreachable2(A obj) {
  bar(
    int.parse('12'),
    obj.foo(10, (throw 'Bye'), int.parse('13')),
    int.parse('14'),
  );
  print(2);
}

void unreachableBreak1(int n) {
  for (var i = 0; i < n; ++i) {
    if (i > 2) {
      throw 'Bye';
      break;
    }
  }
}

void unreachableBreak2(int n) {
  for (var i = 0; i < n; ++i) {
    if (i > 2) {
      throw 'Bye';
      break;
    }
    return;
  }
}

void unreachableFinally() {
  try {
    try {} finally {
      print(1);
      throw 'Bye';
      print(2);
    }
  } finally {
    print(3);
    throw 'Bye-bye';
    print(4);
  }
}

void unreachableTryEnd() {
  try {
    print(1);
    throw 'Bye-bye';
    print(2);
  } catch (_) {
    print(3);
  }
}

void unreachableCatchEnd() {
  try {
    print(1);
  } catch (_) {
    print(2);
    throw 'Bye-bye';
    print(3);
  }
}

void unreachableBothTryEndAndCatchEnd() {
  try {
    print(1);
    throw 'Bye';
    print(2);
  } catch (_) {
    print(3);
    throw 'Bye-bye';
    print(4);
  }
}

List<num> unreachableFieldInitializer = [10, 1 + (throw 'Bye') + 2, 20];

String unreachableStringInterpolation(int x, int y) =>
    'x = $x, boom = ${throw 'Bye'}, y = $y';

List<int> unreachableListLiteral() => [
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  (throw 'Bye'),
  10,
  11,
];

Map<int, String> unreachableMapLiteral() => {
  10: 'aa',
  20: 'bb',
  30: (throw 'Bye'),
  40: 'dd',
};

bool unreachableLogicExpr(bool c1, bool c2, bool c3) =>
    !(c1 && (c2 || (throw 'Bye') || c3));

void main() {}
