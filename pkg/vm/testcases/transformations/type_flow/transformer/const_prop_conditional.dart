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
}
