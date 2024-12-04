// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a type followed by `? when` is correctly parsed.

import 'package:expect/expect.dart';

import 'package:expect/static_type_helper.dart';

void nullableTypeInsideGuardedCastPattern() {
  bool matched(Object? x, bool b) {
    switch (x) {
      case var y as int? when b:
        y.expectStaticType<Exactly<int?>>();
        return true;
      default:
        return false;
    }
  }

  Expect.isTrue(matched(null, true));
  Expect.isTrue(matched(0, true));
  Expect.isFalse(matched(0, false));
  Expect.throws<TypeError>(() => matched('', true));
}

void nonNullableTypeInsideAsExpressionInsideConditional() {
  Object? f(Object? condition, Object? when, Object? otherwise) =>
      condition as bool ? when : otherwise;
  Expect.equals('a', f(true, 'a', 'b'));
  Expect.equals('b', f(false, 'a', 'b'));
}

void nonNullableTypeInsideIsExpressionInsideConditional() {
  Object? f(Object? obj, Object? when, Object? otherwise) =>
      obj is int ? when : otherwise;
  Expect.equals('a', f(0, 'a', 'b'));
  Expect.equals('b', f('x', 'a', 'b'));
}

main() {
  nullableTypeInsideGuardedCastPattern();
  nonNullableTypeInsideAsExpressionInsideConditional();
  nonNullableTypeInsideIsExpressionInsideConditional();
}
