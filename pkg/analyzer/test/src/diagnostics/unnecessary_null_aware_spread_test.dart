// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullAwareSpreadTest);
  });
}

@reflectiveTest
class UnnecessaryNullAwareSpreadTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  test_nonNullableSpread_nullableType() async {
    await assertNoErrorsInCode('''
f(List<int> x) {
  [...x];
}
''');
  }

  test_nullableSpread_legacyType() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
var x = <int>[];
''');

    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  [...?x];
}
''');
  }

  test_nullableSpread_nonNullableType() async {
    await assertErrorsInCode('''
f(List<int> x) {
  [...?x];
}
''', [
      error(StaticWarningCode.UNNECESSARY_NULL_AWARE_SPREAD, 20, 4),
    ]);
  }

  test_nullableSpread_nullableType() async {
    await assertNoErrorsInCode('''
f(List<int>? x) {
  [...?x];
}
''');
  }
}
