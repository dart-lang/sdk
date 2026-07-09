// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion works with null-aware cascades.

import 'package:expect/static_type_helper.dart';

class C {
  final Object? _field;
  C([this._field]);
  void f([_]) {}
}

void fieldsPromotableWithinCascade(C? c) {
  // Within a cascade, a field can be promoted using `!`.
  c
    ?.._field.expectStaticType<Exactly<Object?>>()
    .._field!.expectStaticType<Exactly<Object>>()
    .._field.expectStaticType<Exactly<Object>>();
  // After the cascade, the promotion is not retained, because of the implicit
  // control flow join implied by the `?..`. (In principle it would be sound to
  // preserve the promotion, but it's extra work to do so, and it's not clear
  // that there would be enough user benefit to justify the work).
  c?._field.expectStaticType<Exactly<Object?>>();
}

void cascadeExpressionIsNotPromotable(Object? o) {
  // However, null-checking, casting, or type checking the result of a cascade
  // expression does not promote the target of the cascade. (It could, in
  // principle, but it would be extra work to implement, and it seems unlikely
  // that it would be of much benefit).
  (o?..toString())!;
  o.expectStaticType<Exactly<Object?>>();
  (o?..toString()) as Object;
  o.expectStaticType<Exactly<Object?>>();
  if ((o?..toString()) is Object) {
    o.expectStaticType<Exactly<Object?>>();
  }
}

void ephemeralValueFieldsArePromotable(C? Function() getC) {
  // Fields of an ephemeral value (one that is not explicitly stored in a
  // variable) can still be promoted in one cascade section, and the results of
  // the promotion can be seen in later cascade sections.
  getC()
    ?.._field.expectStaticType<Exactly<Object?>>()
    .._field!.expectStaticType<Exactly<Object>>()
    .._field.expectStaticType<Exactly<Object>>();
  // But they won't be seen if a fresh value is created.
  getC()?._field.expectStaticType<Exactly<Object?>>();
}

void writeCapturedValueFieldsArePromotable(C? c) {
  // Fields of a write-captured variable can still be promoted in one cascade
  // section, and the results of the promotion can be seen in later cascade
  // sections. This is because the target of the cascade is stored in an
  // implicit temporary variable, separate from the write-captured variable.
  f() {
    c = C(null);
  }

  c
    ?.._field.expectStaticType<Exactly<Object?>>()
    .._field!.expectStaticType<Exactly<Object>>()
    .._field.expectStaticType<Exactly<Object>>();
  // But fields of the write-captured variable itself aren't promoted.
  c?._field.expectStaticType<Exactly<Object?>>();
}

main() {
  fieldsPromotableWithinCascade(C(0));
  cascadeExpressionIsNotPromotable(0);
  ephemeralValueFieldsArePromotable(() => C(0));
  writeCapturedValueFieldsArePromotable(C(0));
}
