// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=promotion-chain-intersection-join

// Tests the behavior of the enhanced promotion chain join algorithm
// (https://github.com/dart-lang/language/issues/4757) when enabled.

import 'package:expect/static_type_helper.dart';

class A {}

class B implements A {}

class C implements A {}

class D implements B, C {
  void dMethod() {}
}

void testIfElseAs(bool condition, bool condition2, Object o) {
  if (condition) {
    o as A;
    if (condition2) {
      o as B;
      o as D;
    } else {
      o as C;
      o as D;
    }
    // When promotion-chain-intersection-join is enabled, o retains promotion to
    // D across the join.
    o.expectStaticType<Exactly<D>>();
    o.dMethod();

    // To verify that `A` is still in the promotion chain, join with a control
    // flow path that promotes only to `A`, and verify that the promotion to `A`
    // is preserved:
  } else {
    o as A;
  }
  o.expectStaticType<Exactly<A>>();
}

void testIfElseIs(bool condition, bool condition2, Object o) {
  if (condition) {
    o as A;
    if (condition2) {
      if (o is! B || o is! D) return;
    } else {
      if (o is! C || o is! D) return;
    }
    o.expectStaticType<Exactly<D>>();
    o.dMethod();

    // To verify that `A` is still in the promotion chain, join with a control
    // flow path that promotes only to `A`, and verify that the promotion to `A`
    // is preserved:
  } else {
    o as A;
  }
  o.expectStaticType<Exactly<A>>();
}

void testConditional(bool condition, bool condition2, Object o) {
  if (condition) {
    o as A;
    condition2 ? (o as B, o as D) : (o as C, o as D);
    o.expectStaticType<Exactly<D>>();
    o.dMethod();

    // To verify that `A` is still in the promotion chain, join with a control
    // flow path that promotes only to `A`, and verify that the promotion to `A`
    // is preserved:
  } else {
    o as A;
  }
  o.expectStaticType<Exactly<A>>();
}

void testSwitch(int x, bool condition2, Object o) {
  if (condition2) {
    o as A;
    switch (x) {
      case 1:
        o as B;
        o as D;
      default:
        o as C;
        o as D;
    }
    o.expectStaticType<Exactly<D>>();
    o.dMethod();

    // To verify that `A` is still in the promotion chain, join with a control
    // flow path that promotes only to `A`, and verify that the promotion to `A`
    // is preserved:
  } else {
    o as A;
  }
  o.expectStaticType<Exactly<A>>();
}

void main() {
  for (var condition in [true, false]) {
    for (var condition2 in [true, false]) {
      testIfElseAs(condition, condition2, D());
      testIfElseIs(condition, condition2, D());
      testConditional(condition, condition2, D());
      testSwitch(condition ? 1 : 2, condition2, D());
    }
  }
}
