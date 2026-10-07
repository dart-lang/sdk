// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the enhanced promotion chain join algorithm
// (https://github.com/dart-lang/language/issues/4757) does not take effect when
// the `promotion-chain-intersection-join` feature flag is disabled.

// @dart=3.13

import 'package:expect/static_type_helper.dart';

class A {}

class B implements A {}

class C implements A {}

class D implements B, C {}

void testIfElseAs(bool condition, Object o) {
  o as A;
  if (condition) {
    o as B;
    o as D;
  } else {
    o as C;
    o as D;
  }
  o.expectStaticType<Exactly<A>>();
}

void testIfElseIs(bool condition, Object o) {
  o as A;
  if (condition) {
    if (o is! B || o is! D) return;
  } else {
    if (o is! C || o is! D) return;
  }
  o.expectStaticType<Exactly<A>>();
}

void testConditional(bool condition, Object o) {
  o as A;
  condition ? (o as B, o as D) : (o as C, o as D);
  o.expectStaticType<Exactly<A>>();
}

void testSwitch(int x, Object o) {
  o as A;
  switch (x) {
    case 1:
      o as B;
      o as D;
    default:
      o as C;
      o as D;
  }
  o.expectStaticType<Exactly<A>>();
}

void main() {
  testIfElseAs(true, D());
  testIfElseAs(false, D());
  testIfElseIs(true, D());
  testIfElseIs(false, D());
  testConditional(true, D());
  testConditional(false, D());
  testSwitch(1, D());
  testSwitch(2, D());
}
