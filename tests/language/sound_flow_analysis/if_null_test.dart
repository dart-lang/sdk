// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of if-null expressions (expressions involving `??`)
// when `sound-flow-analysis` is enabled.

// SharedOptions=--enable-experiment=sound-flow-analysis

// ignore_for_file: dead_null_aware_expression

import '../static_type_helper.dart';

// `<nonNullable> ?? <expr>` is known to skip <expr>.
testIfNull({required int intValue, required int Function() intFunction}) {
  {
    // <var> ?? <expr>
    int? shouldNotBeDemoted = 0;
    intValue ?? (shouldNotBeDemoted = null, 0).$2;
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> ?? <expr>
    int? shouldNotBeDemoted = 0;
    intFunction() ?? (shouldNotBeDemoted = null, 0).$2;
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }
}

// `<nonNullable> ??= <expr>` is known to skip <expr>.
testIfNullAssign({required int intValue, required List<int> listOfIntValue}) {
  {
    // <var> ??= <expr>
    int? shouldNotBeDemoted = 0;
    intValue ??= (shouldNotBeDemoted = null, 0).$2;
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }

  {
    // <promotedVar> ??= <expr>
    int? nullableIntValue = 0; // promote to `int`
    int? shouldNotBeDemoted = 0;
    nullableIntValue ??= (shouldNotBeDemoted = null, 0).$2;
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }

  {
    // <property> ??= <expr>
    int? shouldNotBeDemoted = 0;
    listOfIntValue.first ??= (shouldNotBeDemoted = null, 0).$2;
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }

  {
    // <indexOperation> ??= <expr>
    int? shouldNotBeDemoted = 0;
    listOfIntValue[0] ??= (shouldNotBeDemoted = null, 0).$2;
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }
}

main() {
  testIfNull(intValue: 0, intFunction: () => 0);
  testIfNullAssign(intValue: 0, listOfIntValue: [0]);
}
