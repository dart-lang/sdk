// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests constant propagation inside considitonals.

void testStringLiteral(String s) {
  print(s);
}

void testStringConstant(String s) {
  print(s);
}

void testIntLiteral(int i) {
  print(i);
}

void testIntConstant(int i) {
  print(i);
}

void testDefaultEq1(DefaultEq c) {
  print(c);
}

void testDefaultEq2(DefaultEq c) {
  print(c);
}

void testOverriddenEq1(OverriddenEq c) {
  print(c);
}

void testOverriddenEq2(OverriddenEq c) {
  print(c);
}

bool get runtimeTrue => int.parse('1') == 1;

class DefaultEq {
  final int i;

  const DefaultEq(this.i);

  @override
  String toString() => 'DefaultEq(i=$i)';
}

class OverriddenEq {
  final int i;

  const OverriddenEq(this.i);

  @override
  bool operator ==(Object other) {
    return true;
  }

  @override
  String toString() => 'OverriddenEq(i=$i)';
}

void testDoubleLiteral1(double i) {
  print(i);
}

void testDoubleLiteral2(double i) {
  print(i);
}

void testDoubleLiteral3(double i) {
  print(i);
}

void testDoubleConstant1(double i) {
  print(i);
}

void testDoubleConstant2(double i) {
  print(i);
}

void testDoubleConstant3(double i) {
  print(i);
}

void main() {
  final s1 = runtimeTrue ? "foo" : "bar";
  if (s1 == "foo") {
    testStringLiteral(s1);
  }

  final s2 = runtimeTrue ? "1234" : "asdf";
  const sConst = "1234";
  if (s2 == sConst) {
    testStringConstant(s2);
  }

  final i1 = runtimeTrue ? 123 : 456;
  if (i1 == 123) {
    testIntLiteral(i1);
  }

  final i2 = runtimeTrue ? 456 : 789;
  const iConst = 456;
  if (i2 == iConst) {
    testIntConstant(i2);
  }

  final c1 = runtimeTrue ? DefaultEq(1) : DefaultEq(2);
  if (c1 == const DefaultEq(1)) {
    testDefaultEq1(c1); // should propagate
  }

  if (c1 == sConst) {
    testDefaultEq2(c1); // OK to propagate as the branch won't be taken
  }

  final c2 = runtimeTrue ? OverriddenEq(1) : OverriddenEq(2);
  if (c2 == const OverriddenEq(1)) {
    testOverriddenEq1(c2); // should not propagate
  }

  if (c2 == sConst) {
    testOverriddenEq2(c2); // should not propagate
  }

  final d1 = runtimeTrue ? 1.21 : 3.41;
  if (d1 == 1.2) {
    testDoubleLiteral1(d1); // should propagate
  }

  const d1Const = 12.34;
  if (d1 == d1Const) {
    testDoubleConstant1(d1); // should propagate
  }

  final d2 = runtimeTrue ? 1.34 : 5.67;
  if (d2 == double.nan) {
    testDoubleLiteral2(d2); // should not propagate
  }

  const d2Const = double.nan;
  if (d2 == d2Const) {
    testDoubleConstant2(d2); // should not propagate
  }

  final d3 = runtimeTrue ? 8.7 : 9.6;
  if (d3 == -0.0) {
    testDoubleLiteral3(d3); // should not propagate
  }

  const d3Const = -0.0;
  if (d3 == d3Const) {
    testDoubleConstant3(d3); // should not propagate
  }
}
