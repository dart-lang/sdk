// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of a trivially satisfied type check (an `is` test
// that is guaranteed to succeed) when `sound-flow-analysis` is enabled.

// SharedOptions=--enable-experiment=sound-flow-analysis

import '../static_type_helper.dart';

// If `x` is of type `T`, flow analysis considers `x is T` to be guaranteed to
// evaluate to `true`.
void testIsExact({required int intValue, required int Function() intFunction}) {
  {
    // <var> is int
    int? shouldBePromoted;
    int? shouldNotBeDemoted = 0;
    if (intValue is int) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
      // `intValue` is not promoted to `Never`. Note: since
      // `Never.expectStaticType<anything>` will silently succeed, we check this
      // by first wrapping `intValue` in a list, and then checking the type of
      // the list.
      [intValue].expectStaticType<Exactly<List<int>>>();
    }
    shouldBePromoted.expectStaticType<Exactly<int>>();
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> is int
    int? shouldBePromoted;
    int? shouldNotBeDemoted = 0;
    if (intFunction() is int) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldBePromoted.expectStaticType<Exactly<int>>();
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }
}

// If `x` is of type `T`, flow analysis considers `x is! T` to be guaranteed
// to evaluate to `false`.
void testIsNotExact({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var> is! int
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue is! int) {
      shouldNotBeDemoted = null; // Unreachable
      // `intValue` is not promoted to `Never`. Note: since
      // `Never.expectStaticType<anything>` will silently succeed, we check this
      // by first wrapping `intValue` in a list, and then checking the type of
      // the list.
      [intValue].expectStaticType<Exactly<List<int>>>();
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> is! int
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() is! int) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// If `x` is of type `T`, and `T <: U`, flow analysis considers `x is U` to be
// guaranteed to evaluate to `true`.
void testIsSupertype({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var> is num
    int? shouldBePromoted;
    int? shouldNotBeDemoted = 0;
    if (intValue is num) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
      // `intValue` is not promoted to `Never`. Note: since
      // `Never.expectStaticType<anything>` will silently succeed, we check this
      // by first wrapping `intValue` in a list, and then checking the type of
      // the list.
      [intValue].expectStaticType<Exactly<List<int>>>();
    }
    shouldBePromoted.expectStaticType<Exactly<int>>();
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> is num
    int? shouldBePromoted;
    int? shouldNotBeDemoted = 0;
    if (intFunction() is num) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldBePromoted.expectStaticType<Exactly<int>>();
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }
}

// If `x` is of type `T`, and `T <: U`, flow analysis considers `x is! U` to be
// guaranteed to evaluate to `false`.
void testIsNotSupertype({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var> is! num
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue is! num) {
      shouldNotBeDemoted = null; // Unreachable
      // `intValue` is not promoted to `Never`. Note: since
      // `Never.expectStaticType<anything>` will silently succeed, we check this
      // by first wrapping `intValue` in a list, and then checking the type of
      // the list.
      [intValue].expectStaticType<Exactly<List<int>>>();
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> is! num
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() is! num) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

main() {
  testIsExact(intValue: 0, intFunction: () => 0);
  testIsNotExact(intValue: 0, intFunction: () => 0);
  testIsSupertype(intValue: 0, intFunction: () => 0);
  testIsNotSupertype(intValue: 0, intFunction: () => 0);
}
