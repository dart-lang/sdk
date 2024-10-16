// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion works with null-aware cascades whose targets are
// non-nullable (that is, the cascades are "unnecessarily" null-aware).
//
// Since the cascades are unnecessarily null-aware, the analyzer produces
// warnings for it, so this test has to have "error" expectations.

import 'package:expect/static_type_helper.dart';

class C {
  final Object? _field;
  C([this._field]);
  void f([_]) {}
}

void cascadedAccessReceivesTheBenefitOfPromotion(C c) {
  // If a field of an object is promoted prior to its use in a cascade, accesses
  // to the field within cascade sections retain the promotion.
  c._field as int;
  c._field.expectStaticType<Exactly<int>>();
  c
    ?.._field.expectStaticType<Exactly<int>>()
//  ^^^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    .._field.expectStaticType<Exactly<int>>();

  // And the promotion remains on later accesses to the same variable.
  c._field.expectStaticType<Exactly<int>>();
}

void fieldAccessOnACascadeExpressionRetainsPromotion(C c) {
  // If a field of an object is promoted prior to its use in a cascade, accesses
  // to the field from outside the cascade retain the promotion.
  c._field as int;
  c._field.expectStaticType<Exactly<int>>();
  (c?..f())._field.expectStaticType<Exactly<int>>();
//  ^^^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  // And the promotion remains on later accesses to the same variable.
  c._field.expectStaticType<Exactly<int>>();
}

void fieldsPromotableWithinCascade(C c) {
  // Within a cascade, a field can be promoted using `!`.
  c
    ?.._field.expectStaticType<Exactly<Object?>>()
//  ^^^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    .._field!.expectStaticType<Exactly<Object>>()
    .._field.expectStaticType<Exactly<Object>>();

  // After the cascade, the promotion is not retained, because of the implicit
  // control flow join implied by the `?..`. (In principle it would be sound to
  // preserve the promotion, but it's extra work to do so, and it's not clear
  // that there would be enough user benefit to justify the work).
  c?._field.expectStaticType<Exactly<Object?>>();
// ^^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
}

void ephemeralValueFieldsArePromotable(C Function() getC) {
  // Fields of an ephemeral value (one that is not explicitly stored in a
  // variable) can still be promoted in one cascade section, and the results of
  // the promotion can be seen in later cascade sections.
  getC()
    ?.._field.expectStaticType<Exactly<Object?>>()
//  ^^^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    .._field!.expectStaticType<Exactly<Object>>()
    .._field.expectStaticType<Exactly<Object>>();

  // But they won't be seen if a fresh value is created.
  getC()._field.expectStaticType<Exactly<Object?>>();
}

void writeCapturedValueFieldsArePromotable(C c) {
  // Fields of a write-captured variable can still be promoted in one cascade
  // section, and the results of the promotion can be seen in later cascade
  // sections. This is because the target of the cascade is stored in an
  // implicit temporary variable, separate from the write-captured variable.
  f() {
    c = C(null);
  }

  c
    ?.._field.expectStaticType<Exactly<Object?>>()
//  ^^^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    .._field!.expectStaticType<Exactly<Object>>()
    .._field.expectStaticType<Exactly<Object>>();

  // But fields of the write-captured variable itself aren't promoted.
  c._field.expectStaticType<Exactly<Object?>>();
}

void writeDefeatsLaterAccessesButNotCascadeTarget(C c) {
  // If a write to a variable happens during a cascade, any promotions based on
  // that variable are invalidated, but the target of the cascade remains
  // promoted, since it's stored in an implicit temporary variable that's
  // unaffected by the write.
  c._field as C;
  c._field.expectStaticType<Exactly<C>>();
  c
    ?.._field.f([c = C(C()), c._field.expectStaticType<Exactly<Object?>>()])
//  ^^^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    .._field.expectStaticType<Exactly<C>>();
  c._field.expectStaticType<Exactly<Object?>>();
}

void cascadedInvocationsPermitted(C c) {
  // A promoted field may be invoked inside a cascade.
  c._field as int Function();
  c._field.expectStaticType<Exactly<int Function()>>();
  c?.._field().expectStaticType<Exactly<int>>();
}

main() {
  cascadedAccessReceivesTheBenefitOfPromotion(C(0));
  fieldAccessOnACascadeExpressionRetainsPromotion(C(0));
  fieldsPromotableWithinCascade(C(0));
  ephemeralValueFieldsArePromotable(() => C(0));
  writeCapturedValueFieldsArePromotable(C(0));
  writeDefeatsLaterAccessesButNotCascadeTarget(C(C()));
  int f() => 0;
  cascadedInvocationsPermitted(C(f));
}
