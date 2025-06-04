// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of a trivially satisfied type check (an `is` test
// that is guaranteed to succeed) when `sound-flow-analysis` is disabled.

// @dart = 3.8

import '../static_type_helper.dart';

// If `x` is of type `T`, flow analysis does not consider `x is T` to be
// guaranteed to evaluate to `true`.
testIsExact({required int intValue, required int Function() intFunction}) {
  {
    // <var> is int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intValue is int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
      // `intValue` is not promoted to `Never`. Note: since
      // `Never.expectStaticType<anything>` will silently succeed, we check this
      // by first wrapping `intValue` in a list, and then checking the type of
      // the list.
      [intValue].expectStaticType<Exactly<List<int>>>();
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> is int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intFunction() is int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// If `x` is of type `T`, flow analysis does not consider `x is! T` to be
// guaranteed to evaluate to `false`.
testIsNotExact({required int intValue, required int Function() intFunction}) {
  {
    // <var> is! int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intValue is! int) {
      shouldBeDemoted1 = null;
      // `intValue` is not promoted to `Never`. Note: since
      // `Never.expectStaticType<anything>` will silently succeed, we check this
      // by first wrapping `intValue` in a list, and then checking the type of
      // the list.
      [intValue].expectStaticType<Exactly<List<int>>>();
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> is! int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intFunction() is! int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// If `x` is of type `T`, and `T <: U`, flow analysis does not consider `x is U`
// to be guaranteed to evaluate to `true`.
testIsSupertype({required int intValue, required int Function() intFunction}) {
  {
    // <var> is num
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intValue is num) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
      // `intValue` is not promoted to `Never`. Note: since
      // `Never.expectStaticType<anything>` will silently succeed, we check this
      // by first wrapping `intValue` in a list, and then checking the type of
      // the list.
      [intValue].expectStaticType<Exactly<List<int>>>();
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> is num
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intFunction() is num) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// If `x` is of type `T`, and `T <: U`, flow analysis does not consider `x is!
// U` to be guaranteed to evaluate to `false`.
testIsNotSupertype({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var> is! num
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intValue is! num) {
      shouldBeDemoted1 = null;
      // `intValue` is not promoted to `Never`. Note: since
      // `Never.expectStaticType<anything>` will silently succeed, we check this
      // by first wrapping `intValue` in a list, and then checking the type of
      // the list.
      [intValue].expectStaticType<Exactly<List<int>>>();
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> is! num
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intFunction() is! num) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

main() {
  testIsExact(intValue: 0, intFunction: () => 0);
  testIsNotExact(intValue: 0, intFunction: () => 0);
  testIsSupertype(intValue: 0, intFunction: () => 0);
  testIsNotSupertype(intValue: 0, intFunction: () => 0);
}
