// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: dead_code, dead_code_catch_following_catch

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

class B extends A {
  final int x;
  final int y;

  B(this.x, this.y);
  B.unreachableFieldInit() : x = (throw 'Bye'), y = 10;
  B.unreachableRedirectingInit() : this(throw 'Bye', 20);
}

class C extends B {
  C.unreachableSuperInit() : super(throw 'Bye', 30);
}

void unreachableSwitchExpr() {
  switch (throw 'Bye') {
    case 1:
      print(1);
    default:
      print(2);
  }
}

void unreachableCatchClause() {
  try {
    print(1);
  } catch (e) {
    print(2);
  } on String catch (e) {
    print(e);
  }
}

int unreachableConditional1() => 1 + ((throw 'Bye') ? 2 : 3);

void unreachableConditional2(bool c) {
  bar(10, c ? (throw 'Bye') : 20, 30);
}

num unreachableConditional3(bool c) =>
    1 + (c ? (throw 'Bye1') : (throw 'Bye2'));

int unreachableRecordIndexGet() => ((throw 'Bye') as (int, String)).$1;

String unreachableRecordNameGet() => ((throw 'Bye') as (int, {String b})).b;

(int, String) unreachableRecordLiteral() => (1, throw 'Bye');

void unreachableForInit() {
  for (int i = (throw 'Bye'), j = 10; i < 5; ++i) {
    print(j);
  }
}

void main() {}
