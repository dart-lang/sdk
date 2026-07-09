// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of if-null expressions (expressions involving `??`)
// when `sound-flow-analysis` is disabled.

// @dart = 3.8

// ignore_for_file: dead_null_aware_expression

import '../static_type_helper.dart';

// `<nonNullable> ?? <expr>` is not known to skip <expr>.
testIfNull({required int intValue, required int Function() intFunction}) {
  {
    // <var> ?? <expr>
    int? shouldBeDemoted = 0;
    intValue ?? (shouldBeDemoted = null, 0).$2;
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> ?? <expr>
    int? shouldBeDemoted = 0;
    intFunction() ?? (shouldBeDemoted = null, 0).$2;
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable> ??= <expr>` is not known to skip <expr>.
testIfNullAssign({required int intValue, required List<int> listOfIntValue}) {
  {
    // <var> ??= <expr>
    int? shouldBeDemoted = 0;
    intValue ??= (shouldBeDemoted = null, 0).$2;
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <promotedVar> ??= <expr>
    int? nullableIntValue = 0; // promote to `int`
    int? shouldBeDemoted = 0;
    nullableIntValue ??= (shouldBeDemoted = null, 0).$2;
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <property> ??= <expr>
    int? shouldBeDemoted = 0;
    listOfIntValue.first ??= (shouldBeDemoted = null, 0).$2;
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <indexOperation> ??= <expr>
    int? shouldBeDemoted = 0;
    listOfIntValue[0] ??= (shouldBeDemoted = null, 0).$2;
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }
}

main() {
  testIfNull(intValue: 0, intFunction: () => 0);
  testIfNullAssign(intValue: 0, listOfIntValue: [0]);
}
