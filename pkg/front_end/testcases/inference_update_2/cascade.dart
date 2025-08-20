// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From language/inference_update_2/
//   cascaded_field_promotion_unnecessary_null_aware_error_test

class C {
  final Object? _field;
  C([this._field]);
  void f([_]) {}
}

void fieldsPromotableWithinCascade(C c) {
  // Within a cascade, a field can be promoted using `!`.
  c
    ?.._field.expectStaticType<Exactly<Object?>>()
    .._field!.expectStaticType<Exactly<Object>>()
    .._field.expectStaticType<Exactly<Object>>();
  // After the cascade, the promotion is retained, because in the implicit
  // control flow join implied by the `?..`, the control flow path that skips
  // the promotion is dead.
  c?._field.expectStaticType<Exactly<Object>>();
}

typedef Exactly<T> = T Function(T);

extension StaticType<T> on T {
  T expectStaticType<R extends Exactly<T>>() {
    return this;
  }
}
