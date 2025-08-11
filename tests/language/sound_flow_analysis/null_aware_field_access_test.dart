// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the interactions between field promotion and various forms of
// null-aware accesses, when `sound-flow-analysis` is enabled.

// Note that there is (as of this writing) no specification for field promotion;
// this test reflects the current behavior of the `sound-flow-analysis` feature,
// as discussed in https://github.com/dart-lang/language/issues/4344.

// SharedOptions=--enable-experiment=sound-flow-analysis

// ignore_for_file: invalid_null_aware_operator

import 'package:expect/static_type_helper.dart';

class A {
  final int? _i;
  A(this._i);
}

// Inside a non-cascaded null-aware field access, prior promotions take effect.
void nonCascadedPriorPromotion(A a) {
  if (a._i != null) {
    // `a._i` is promoted now.
    a._i.expectStaticType<Exactly<int>>();
    // And so is `a?._i`.
    a?._i.expectStaticType<Exactly<int>>();
  }
}

// A promotion that occurs inside a non-cascaded null-aware field access
// produces a continued effect after the field access.
void nonCascadedPromotionAfter(A a) {
  a?._i!;
  // `a._i` is now promoted.
  a._i.expectStaticType<Exactly<int>>();
  // And so is `a?._i`.
  a?._i.expectStaticType<Exactly<int>>();
}

// Inside a cascaded null-aware field access, prior promotions take effect.
void cascadedPriorPromotion(A a) {
  if (a._i != null) {
    // `a._i` is promoted now.
    a._i.expectStaticType<Exactly<int>>();
    // And `a?.._i` is promoted.
    a?.._i.expectStaticType<Exactly<int>>();
  }
}

// A promotion that occurs inside a cascaded null-aware field access produces a
// continued effect after the cascade (assuming the target is non-nullable).
void cascadedPromotionAfter(A a) {
  // `a._i` is promoted inside the cascade
  a
    ?.._i!
    .._i.expectStaticType<Exactly<int>>();
  // And the promotion is retained afterwards.
  a._i.expectStaticType<Exactly<int>>();
}

// A promotion that occurs inside a cascaded null-aware field access produces an
// effect on the value of the cascade expression (assuming the target is
// non-nullable).
void cascadedPromotionValue(A a) {
  // `a._i` is promoted inside the cascade
  (a
        ?.._i!
        .._i.expectStaticType<Exactly<int>>())
      // And the promotion is retained in the value of the cascade expression.
      ._i
      .expectStaticType<Exactly<int>>();
}

main() {
  nonCascadedPriorPromotion(A(0));
  nonCascadedPromotionAfter(A(0));
  cascadedPriorPromotion(A(0));
  cascadedPromotionAfter(A(0));
  cascadedPromotionValue(A(0));
}
